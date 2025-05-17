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

    // 지도 뷰와 옵션/컨트롤러
    private let naverMap: NMFNaverMapView
    private let options: NaverMapViewOptions
    private let overlayController: OverlayController
    private let naverMapControlSender: NaverMapControlSender
    private var eventDelegate: NaverMapViewEventDelegate!

    init(frame: CGRect,
         options: NaverMapViewOptions,
         channel: FlutterMethodChannel,
         overlayController: OverlayController) {
        // 1) 채널 저장
        self.channel = channel

        // 2) 지도 초기화
        self.naverMap = NMFNaverMapView(frame: frame)
        self.options = options
        self.overlayController = overlayController
        self.naverMapControlSender = NaverMapController(
            naverMap: naverMap,
            channel: channel,
            overlayController: overlayController
        )

        super.init()

        // 3) Dart → Native 호출 받을 핸들러 등록
        channel.setMethodCallHandler(handleMethodCall(_:result:))

        // 4) 첫 번째 옵션 적용
        options.updateWithNaverMapView(naverMap: naverMap, isFirst: true)

        // 5) 나머지 초기화
        onMapReady()
    }

    func view() -> UIView {
        return naverMap
    }

    deinit {
        // 채널 끊기
        (naverMapControlSender as? NaverMapController)?.removeChannel()
    }

    private func onMapReady() {
        setMapTapListener()
        naverMapControlSender.onMapReady()
        deactivateLogo()
    }

    private func deactivateLogo() {
        // 네이버 로고 숨기기
        let subviews = naverMap.mapView.subviews
        if subviews.count > 1 {
            subviews[1].isHidden = true
        }
    }

    private func setMapTapListener() {
        eventDelegate = NaverMapViewEventDelegate(
            sender: naverMapControlSender,
            initializeConsumeSymbolTapEvents: options.consumeSymbolTapEvents
        )
        eventDelegate.registerDelegates(mapView: naverMap.mapView)
    }

    // Dart → Native 호출 처리
    private func handleMethodCall(_ call: FlutterMethodCall,
                                  result: @escaping FlutterResult) {
        switch call.method {
        case "setLayerGroupEnabled":
            guard let args = call.arguments as? [String: Any],
                  let groupKey = args["layerGroup"] as? String,
                  let enable = args["enable"] as? Bool else {
                return result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected { layerGroup: String, enable: Bool }",
                    details: nil
                ))
            }

            // String → NMF_LAYER_GROUP 매핑
            let layerGroup: NMF_LAYER_GROUP
            switch groupKey {
            case "poi":
                layerGroup = .poi
            case "transit":
                layerGroup = .transit
            case "building":
                layerGroup = .building
            default:
                return result(FlutterError(
                    code: "UNKNOWN_GROUP",
                    message: "Unknown layerGroup: \(groupKey)",
                    details: nil
                ))
            }

            // 네이티브 API 호출
            naverMap.mapView.setLayerGroup(layerGroup, isEnabled: enable)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}