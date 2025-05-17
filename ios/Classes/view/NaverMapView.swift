//
//  NaverMapView.swift
//  flutter_naver_map
//

import Flutter
import UIKit
import NMapsMap

internal class NaverMapView: NSObject, FlutterPlatformView {
    // 1) Dart ↔ Native 통신 채널 저장
    private let channel: FlutterMethodChannel
    // 기존 프로퍼티들
    private let naverMap: NMFNaverMapView!
    private let naverMapViewOptions: NaverMapViewOptions
    private let naverMapControlSender: NaverMapControlSender
    private var eventDelegate: NaverMapViewEventDelegate!

    // 2) init 시 channel을 전달받아 저장
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

        // 3) 최초 옵션 적용
        naverMapViewOptions.updateWithNaverMapView(
            naverMap: naverMap,
            isFirst: true
        )

        // 4) Dart → Native 호출을 받을 handler 등록
        channel.setMethodCallHandler(handleMethodCall(_:result:))

        // 5) 나머지 onMapReady 로직
        onMapReady()
    }

    func view() -> UIView {
        return naverMap
    }

    deinit {
        // 채널 정리
        (naverMapControlSender as! NaverMapController).removeChannel()
    }

    // 지도 준비 완료 시
    private func onMapReady() {
        setMapTapListener()
        naverMapControlSender.onMapReady()
        deactivateLogo()
    }

    // 네이버 로고 숨기기
    private func deactivateLogo() {
        let subviews = naverMap.mapView.subviews
        if subviews.count > 1 {
            subviews[1].isHidden = true
        }
    }

    // 심볼 터치 리스너 등록
    private func setMapTapListener() {
        eventDelegate = NaverMapViewEventDelegate(
            sender: naverMapControlSender,
            initializeConsumeSymbolTapEvents:
                naverMapViewOptions.consumeSymbolTapEvents
        )
        eventDelegate.registerDelegates(mapView: naverMap.mapView)
    }

    // 6) Dart → Native 호출 처리
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

            // iOS SDK에서는 setLayerGroup(_:isEnabled:) API 사용
            switch group {
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