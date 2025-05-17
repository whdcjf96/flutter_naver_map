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
        
        // 1) 초기 옵션 적용
        options.updateWithNaverMapView(naverMap: naverMap, isFirst: true)
        
        // 2) 채널 핸들러 등록
        channel.setMethodCallHandler(handleMethodCall(_:result:))
        
        // 3) 터치/심볼 이벤트 처리 등록
        eventDelegate = NaverMapViewEventDelegate(
            sender: NaverMapController(
                naverMap: naverMap,
                channel: channel,
                overlayController: overlayController
            ),
            initializeConsumeSymbolTapEvents: options.consumeSymbolTapEvents
        )
        eventDelegate.registerDelegates(mapView: naverMap.mapView)
        
        // 4) 네이버 로고 숨기기
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

    // Dart → Native 호출을 처리
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

            // iOS에서는 poi 레이어가 없어서 traffic으로 매핑하거나, 필요 없는 경우 제외하세요.
            switch key {
            case "traffic":
                naverMap.mapView.setLayerGroup(NMF_LAYER_GROUP_TRAFFIC, isEnabled: enabled)
            case "transit":
                naverMap.mapView.setLayerGroup(NMF_LAYER_GROUP_TRANSIT, isEnabled: enabled)
            case "building":
                naverMap.mapView.setLayerGroup(NMF_LAYER_GROUP_BUILDING, isEnabled: enabled)
            default:
                // 정의되지 않은 키는 구현되지 않음으로 응답
                result(FlutterMethodNotImplemented)
                return
            }

            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}