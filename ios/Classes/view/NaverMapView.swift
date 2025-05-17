// NaverMapView.swift

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
        
        options.updateWithNaverMapView(naverMap: naverMap, isFirst: true)
        channel.setMethodCallHandler(handleMethodCall(_:result:))
        
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
                return result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected { layerGroup:String, enable:Bool }",
                    details: nil
                ))
            }
            
            let group: NMFLayerGroup
            switch key {
            case "poi":      group = .poi
            case "transit":  group = .transit
            case "building": group = .building
            default:
                return result(FlutterMethodNotImplemented)
            }

            naverMap.mapView.setLayerGroup(group, isEnabled: enabled)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}