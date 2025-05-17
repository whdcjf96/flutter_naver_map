//
//  NaverMapView.swift
//  flutter_naver_map
//

import Flutter
import UIKit
import NMapsMap

internal class NaverMapView: NSObject, FlutterPlatformView {
    // Dart ↔ Native 통신 채널
    private let channel: FlutterMethodChannel

    // 지도 뷰와 옵션, 컨트롤러
    private let naverMap: NMFNaverMapView!
    private let options: NaverMapViewOptions
    private let mapController: NaverMapController
    private var eventDelegate: NaverMapViewEventDelegate!

    // 생성자: 채널을 먼저 저장하고 나머지 초기화
    init(frame: CGRect,
         options: NaverMapViewOptions,
         channel: FlutterMethodChannel,
         overlayController: OverlayController) {
        self.channel = channel
        self.naverMap = NMFNaverMapView(frame: frame)
        self.options = options
        self.mapController = NaverMapController(
            naverMap: naverMap,
            channel: channel,
            overlayController: overlayController
        )
        super.init()

        // 1) 최초 옵션 적용
        options.updateWithNaverMapView(naverMap: naverMap, isFirst: true)

        // 2) Dart → Native 호출 처리 핸들러 등록
        channel.setMethodCallHandler(handleMethodCall(_:result:))

        // 3) 맵 준비 완료 로직
        onMapReady()
    }

    // FlutterPlatformView 프로토콜
    func view() -> UIView {
        return naverMap
    }

    deinit {
        // 채널 정리
        mapController.removeChannel()
    }

    // 맵 준비가 끝났을 때
    private func onMapReady() {
        setupTapListener()
        mapController.onMapReady()
        hideLogo()
    }

    // 네이버 로고 숨기기
    private func hideLogo() {
        let subviews = naverMap.mapView.subviews
        if subviews.count > 1 {
            subviews[1].isHidden = true
        }
    }

    // 심볼(마커) 터치 이벤트 리스너 연결
    private func setupTapListener() {
        eventDelegate = NaverMapViewEventDelegate(
            sender: mapController,
            initializeConsumeSymbolTapEvents: options.consumeSymbolTapEvents
        )
        eventDelegate.registerDelegates(mapView: naverMap.mapView)
    }

    // Dart에서 invokeMethod("setLayerGroupEnabled", ...) 호출 시 이쪽으로 들어옵니다
    private func handleMethodCall(_ call: FlutterMethodCall,
                                  result: @escaping FlutterResult) {
        switch call.method {
        case "setLayerGroupEnabled":
            guard
                let args = call.arguments as? [String: Any],
                let groupKey = args["layerGroup"] as? String,
                let enable = args["enable"] as? Bool
            else {
                return result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected { layerGroup: String, enable: Bool }",
                    details: nil
                ))
            }

            // iOS SDK의 setLayerGroup(_:isEnabled:) 호출로 변환
            switch groupKey {
            case "poi":
                naverMap.mapView.setLayerGroup(.poi, isEnabled: enable)
            case "transit":
                naverMap.mapView.setLayerGroup(.transit, isEnabled: enable)
            case "building":
                naverMap.mapView.setLayerGroup(.building, isEnabled: enable)
            default:
                break
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}