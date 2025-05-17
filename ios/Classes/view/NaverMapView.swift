//
//  NaverMapView.swift
//  flutter_naver_map
//

import Flutter
import UIKit
import NMapsMap

internal class NaverMapView: NSObject, FlutterPlatformView {
    // 1) Dart ↔ Native 통신용 채널
    private let channel: FlutterMethodChannel

    // 2) 실제 지도 뷰
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

        // 3) 옵션 초기 적용 (기존 updateWithNaverMapView)
        super.init()
        options.updateWithNaverMapView(naverMap: naverMap, isFirst: true)

        // 4) 채널 핸들러 등록
        channel.setMethodCallHandler(self.handleMethodCall)

        // 5) 나머지 초기화
        eventDelegate = NaverMapViewEventDelegate(
            sender: NaverMapController(
                naverMap: naverMap,
                channel: channel,
                overlayController: overlayController
            ),
            initializeConsumeSymbolTapEvents: options.consumeSymbolTapEvents
        )
        eventDelegate.registerDelegates(mapView: naverMap.mapView)
        deactivateLogo()
    }

    func view() -> UIView {
        return naverMap
    }

    private func deactivateLogo() {
        // 네이버 로고 숨기기
        for sub in naverMap.mapView.subviews where String(describing: type(of: sub)).contains("Logo") {
            sub.isHidden = true
        }
    }

    // 6) Dart → Native 호출 처리
    private func handleMethodCall(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "setLayerGroupEnabled":
            guard
                let args = call.arguments as? [String: Any],
                let groupKey = args["layerGroup"] as? String,
                let enabled = args["enable"] as? Bool
            else {
                return result(
                  FlutterError(code: "INVALID_ARGS",
                               message: "layerGroup:String, enable:Bool 필요",
                               details: nil)
                )
            }

            // 7) 올바른 enum 매핑
            let group: NMFMapLayerGroup
            switch groupKey {
            case "poi":     group = .poi
            case "transit": group = .transit
            case "building":group = .building
            default:
                return result(FlutterMethodNotImplemented)
            }

            // 8) 토글 호출
            naverMap.mapView.setLayerGroup(group, isEnabled: enabled)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}