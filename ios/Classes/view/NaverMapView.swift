import NMapsMap

internal class NaverMapView: NSObject, FlutterPlatformView {
    private let naverMap: NMFNaverMapView!
    private let naverMapViewOptions: NaverMapViewOptions
    private let naverMapControlSender: NaverMapControlSender
    private var eventDelegate: NaverMapViewEventDelegate!

    init(frame: CGRect, options: NaverMapViewOptions, channel: FlutterMethodChannel, overlayController: OverlayController) {

        // ++
        self.channel = channel

        naverMap = NMFNaverMapView(frame: frame)
        naverMapViewOptions = options
        naverMapControlSender = NaverMapController(naverMap: naverMap, channel: channel, overlayController: overlayController)
        super.init()

        naverMapViewOptions.updateWithNaverMapView(naverMap: naverMap, isFirst: true)

        // ++① Dart → Native 호출받기
        channel.setMethodCallHandler(handleMethodCall(_:result:))

        onMapReady()
    }

    // ++② 실제 호출을 처리하는 핸들러
    private func handleMethodCall(_ call: FlutterMethodCall,
                                  result: @escaping FlutterResult) {
        switch call.method {
        case "setLayerGroupEnabled":
            guard let args = call.arguments as? [String:Any],
                  let group = args["layerGroup"] as? String,
                  let enable = args["enable"] as? Bool else {
                return result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Expected { layerGroup:String, enable:Bool }",
                    details: nil
                ))
            }
            switch group {
            case "poi":      naverMap.mapView.setLayerGroupEnabled(.poi, enable)
            case "transit":  naverMap.mapView.setLayerGroupEnabled(.transit, enable)
            case "building": naverMap.mapView.setLayerGroupEnabled(.building, enable)
            default: break
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func onMapReady() {
        setMapTapListener()
        naverMapControlSender.onMapReady()
        deactivateLogo()
    }
    
    private func deactivateLogo() {
        let subviews = naverMap.mapView.subviews
        print("subViews: \(subviews.debugDescription)")
        let logoIncludedView = subviews[1]
        logoIncludedView.isHidden = true
    }

    private func setMapTapListener() {
        eventDelegate = NaverMapViewEventDelegate(sender: naverMapControlSender,
                initializeConsumeSymbolTapEvents: naverMapViewOptions.consumeSymbolTapEvents)
        eventDelegate.registerDelegates(mapView: naverMap.mapView)
    }

    func view() -> UIView {
        naverMap
    }

    deinit {
        (naverMapControlSender as! NaverMapController).removeChannel()
    }
}

