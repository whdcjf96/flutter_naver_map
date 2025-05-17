//
//  NaverMapView.swift
//  flutter_naver_map
//

import Flutter
import UIKit
import NMapsMap

internal class NaverMapView: NSObject, FlutterPlatformView {
    // 1) Dart ↔ Native 통신 채널을 저장할 프로퍼티 추가
    private let channel: FlutterMethodChannel
    // 기존 프로퍼티들
    private let naverMap: NMFNaverMapView!
    private let naverMapViewOptions: NaverMapViewOptions
    private let naverMapControlSender: NaverMapControlSender
    private var eventDelegate: NaverMapViewEventDelegate!

    // 2) init 시 channel을 받고 프로퍼티에 할당
    init(frame: CGRect,
         options: NaverMapViewOptions,
         channel: FlutterMethodChannel,
         overlayController: OverlayController) {
        // 채널 먼저 저장
        self.channel = channel

        // 나머지 기존 초기화
        naverMap = NMFNaverMapView(frame: frame)
        naverMapViewOptions = options
        naverMapControlSender = NaverMapController(
            naverMap: naverMap,
            channel: channel,
            overlayController: overlayController
        )
        super.init()

        // 3) 기존 옵션 적용
        naverMapViewOptions.updateWithNaverMapView(
            naverMap: naverMap,
            isFirst: true
        )

        // 4) 채널 핸들러 등록 (Dart에서 invokeMethod를 받을 부분)
        channel.setMethodCallHandler(handleMethodCall(_:result:))

        // 5) 나머지 기존 로직
        onMapReady()
    }

    func view() -> UIView {
        return naverMap
    }

    deinit {
        (naverMapControlSender as! NaverMapController).removeChannel()
    }

    private func onMapReady() {
        setMapTapListener()
        naverMapControlSender.onMapReady()
        deactivateLogo()
    }

    private func deactivateLogo() {
        let subviews = naverMap.mapView.subviews
        // 네이버 로고 뷰 숨기기
        if subviews.count > 1 {
            subviews[1].isHidden = true
        }
    }

    private func setMapTapListener() {
        eventDelegate = NaverMapViewEventDelegate(
            sender: naverMapControlSender,
            initializeConsumeSymbolTapEvents:
                naverMapViewOptions.consumeSymbolTapEvents
        )
        eventDelegate.registerDelegates(mapView: naverMap.mapView)
    }

    // 6) Dart → Native 호출을 실제로 처리하는 메서드
    private func handleMethodCall(_ call: FlutterMethodCall,
                                  result: @escaping FlutterResult) {
        switch call.method {
        case "setLayerGroupEnabled":
            guard let args = call.arguments as? [String: Any],
                  let group = args["layerGroup"] as? String,
                  let enable = args["enable"] as? Bool else {
                return result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected { layerGroup: String, enable: Bool }",
                    details: nil
                ))
            }

            // 7) 네이티브 API 호출: mapView에 레이어 토글
            switch group {
            case "poi":
                naverMap.mapView.setLayerGroupEnabled(.poi, enable)
            case "transit":
                naverMap.mapView.setLayerGroupEnabled(.transit, enable)
            case "building":
                naverMap.mapView.setLayerGroupEnabled(.building, enable)
            default:
                break
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}