//
//  NaverMapView.swift
//  flutter_naver_map
//

import Flutter
import UIKit
import NMapsMap

internal class NaverMapView: NSObject, FlutterPlatformView {
    private let channel: FlutterMethodChannel
    private let naverMap: NMFNaverMapView
    private let eventDelegate: NaverMapViewEventDelegate

    init(
        frame: CGRect,
        options: NaverMapViewOptions,
        channel: FlutterMethodChannel,
        overlayController: OverlayController
    ) {
        self.channel = channel
        self.naverMap = NMFNaverMapView(frame: frame)
        super.init()
        
        // 초기 옵션 적용
        options.updateWithNaverMapView(naverMap: naverMap, isFirst: true)
        
        // Dart → Native 채널 핸들러 등록
        channel.setMethodCallHandler(handleMethodCall(_:result:))
        
        // 터치/심볼 이벤트 처리
        eventDelegate = NaverMapViewEventDelegate(
            sender: NaverMapController(
                naverMap: naverMap,
                channel: channel,
                overlayController: overlayController
            ),
            initializeConsumeSymbolTapEvents: options.consumeSymbolTapEvents
        )
        eventDelegate.registerDelegates(mapView: naverMap.mapView)
        
        // 네이버 로고 숨기기
        deactivateLogo()
    }

    func view() -> UIView {
        return naverMap
    }

    private func deactivateLogo() {
        for sub in naverMap.mapView.subviews
            where String(describing: type(of: sub)).contains("Logo") {
            sub.isHidden = true
        }
    }

    private func handleMethodCall(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "setLayerGroupEnabled":
            guard
                let args    = call.arguments as? [String: Any],
                let key     = args["layerGroup"] as? String,
                let enabled = args["enable"]    as? Bool
            else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected { layerGroup: String, enable: Bool }",
                    details: nil
                ))
                return
            }

            // iOS 네이티브 레이어 그룹 매핑
            switch key {
            case "traffic":
                naverMap.mapView.setLayerGroup(NMF_LAYER_GROUP_TRAFFIC, isEnabled: enabled)
            case "transit":
                naverMap.mapView.setLayerGroup(NMF_LAYER_GROUP_TRANSIT, isEnabled: enabled)
            case "building":
                naverMap.mapView.setLayerGroup(NMF_LAYER_GROUP_BUILDING, isEnabled: enabled)
            default:
                // POI 레이어 토글은 iOS SDK에 지원되지 않습니다.
                result(FlutterMethodNotImplemented)
                return
            }

            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}