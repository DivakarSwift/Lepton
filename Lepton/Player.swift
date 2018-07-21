//
//  Player.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 20/05/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

public enum PlayerStatus {
    case unknown
    case readyToPlay
    case playing
    case paused
    case playToEndTime
    case failed
}

public enum PlaybackBufferStatus {
    case unknown
    case empty
}

public typealias PlayerView = UIView & ViewRenderer

/// The Player
///
///
public class Player: NSObject {

    /// Auto play when loaded player item
    public var isAutoPlay: Bool = true

    /// The layer where the player item overlay layer display
    public private(set) var synchronizedLayer: AVSynchronizedLayer?

    /// h.264 player
    public let player = AVPlayer()

    /// Player view which use to render pixel buffer
    public let playerView: PlayerView

    /// Current player status
    public private(set) var status: PlayerStatus = .unknown {
        didSet {
            delegate?.player(self, playerView: playerView, statusDidChange: status)
        }
    }

    /// Player delegate
    public weak var delegate: PlayerDelegate?

    /// Current player item presentation size
    public private(set) var presentationSize: CGSize = .zero

    /// Current player time
    public private(set) var currentTime: Float64 = 0.0

    public var suppressesPlayerRendering: Bool = false
    
    private let videoOutputQueue = DispatchQueue(label: "com.blessingsoft.lepton.videoOutput")

    private lazy var videoOutput: AVPlayerItemVideoOutput = {
        let attributes = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: attributes)
        output.setDelegate(self, queue: self.videoOutputQueue)
        output.suppressesPlayerRendering = self.suppressesPlayerRendering
        return output
    }()

    private var isObserving = false
    
    private var lastTimestamp: CFTimeInterval = 0
    
    private var currentItem: PlayerItemProtocol?

    private var preferredTransform: CGAffineTransform = .identity
    
    private struct Constant {
        static let oneFrameDuration: TimeInterval = 0.03
        
        static var playerItemContext = 0
        
        static var timeObserverToken: Any?
    }

    private var playerStatusToken: NSKeyValueObservation?

    private var playerItemStatusToken: NSKeyValueObservation?
    
    /// Tracks whether the display link is initialized.
    private var displayLinkInitialized: Bool = false
    
    lazy var displayLink: CADisplayLink = { [unowned self] in
        self.displayLinkInitialized = true
        let link = CADisplayLink(target: DisplayLinkProxy(target: self), selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .current, forMode: RunLoop.Mode.common)
        link.isPaused = true
        return link
    }()

    public override init() {
        self.playerView = RenderView()
    }

    public init(playerView: PlayerView) {
        self.playerView = playerView
        super.init()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stop()
    }
}

// MARK: - Public Method

extension Player {
    
    public func load(item: PlayerItemProtocol, seekTo seconds: Float64 = 0) {
        currentItem = item
        
        player.pause()
        stopObserving(player: player)
        
        load(asset: item.composition, autoPlay: isAutoPlay)
        load(videoCompostion: item.videoComposition)
        load(audioMix: item.audioMix)
        load(filter: item.filter)
        load(layer: item.overlayLayer, videoSize:item.videoComposition.renderSize)
        
        try? seek(to: seconds)
        
        startObserving(player: player)
    }
    
    public func play() {
        addTimeObserver(from: player)
        player.play()
        displayLink.isPaused = false

        status = .playing
    }
    
    public func pause() {
        guard status == .playing else {
            return
        }

        removeTimeObserver(from: player)
        player.pause()
        displayLink.isPaused = true

        status = .paused
    }
    
    public func stop() {
        removeTimeObserver(from: player)
        stopObserving(player: player)
        player.pause()

        if displayLinkInitialized {
            displayLink.isPaused = true
        }

        status = .unknown
    }

    public func seek(to seconds: Float64, completionHandler: ((Bool) -> Void)? = nil) throws {

        guard let playerItem = player.currentItem else {
            return
        }

        let time = CMTime(seconds: seconds, preferredTimescale: playerItem.asset.duration.timescale)
        guard time.isValid else {
            assert(false, "time is not valid")
            throw PlayerError.timeInvalid
        }

        if let handler = completionHandler {
            player.seek(to: time, completionHandler: handler)
        } else {
            player.seek(to: time)
        }
    }

    public func seek(to seconds: Float64, toleranceBefore: Float64, toleranceAfter: Float64, completionHandler: ((Bool) -> Void)? = nil) throws {

        guard let playerItem = player.currentItem else {
            return
        }

        let time = CMTime(seconds: seconds, preferredTimescale: playerItem.asset.duration.timescale)
        let before = CMTime(seconds: toleranceBefore, preferredTimescale: playerItem.asset.duration.timescale)
        let after = CMTime(seconds: toleranceAfter, preferredTimescale: playerItem.asset.duration.timescale)

        guard time.isValid, before.isValid, after.isValid else {
            assert(false, "time is not valid")
            throw PlayerError.timeInvalid
        }

        if let handler = completionHandler {
            player.seek(to: time, toleranceBefore: before, toleranceAfter: after, completionHandler: handler)
        } else {
            player.seek(to: time, toleranceBefore: before, toleranceAfter: after)
        }
    }
}

// MARK: - Player

extension Player {
    
    public var duration: Float64 {
        
        guard player.status == .readyToPlay, let currentItem = player.currentItem else {
            return 0.0
        }
        
        return currentItem.duration.seconds
    }
    
    public var isMuted: Bool {
        get {
            return player.isMuted
        }
        set {
            player.isMuted = newValue
        }
    }
    
    public var volume: Float {
        get {
            return player.volume
        }
        set {
            player.volume = newValue
        }
    }

    public var isPlaying: Bool {
        return player.rate > 0.0
    }

    public var error: Error? {
        return player.error
    }
}

// MARK: - Load

extension Player {
    
    private func load(asset: AVAsset, autoPlay: Bool) {
        isAutoPlay = autoPlay
        
        // Remove video output from old item, if any.
        player.currentItem?.remove(videoOutput)
        
        let item = AVPlayerItem(asset: asset)
        
        let keysToLoad = ["tracks", "duration", "playable"]
        
        asset.loadValuesAsynchronously(forKeys: keysToLoad) { [unowned self] in
            for key in keysToLoad {
                var error: NSError?
                if asset.statusOfValue(forKey: key, error: &error) == .failed {
                    print("Key value loading failed for key: \(key) with error: \(error!)")
                    self.status = .failed
                    return
                }
            }
            
            guard asset.isPlayable else {
                print("Asset is not playable")
                self.status = .failed
                return
            }

            self.addVideoOutput(to: item)
            
            if autoPlay {
                self.play()
            }
        }
    }

    private func addVideoOutput(to item: AVPlayerItem) {

        item.add(videoOutput)
        player.replaceCurrentItem(with: item)
        videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: Constant.oneFrameDuration)

        guard let track = item.asset.tracks(withMediaType: .video).first else {
            return
        }

        var transform = track.preferredTransform

        if transform.b == 1, transform.c == -1 {
            transform = transform.rotated(by: .pi)
        }

        DispatchQueue.main.async {
            // rotate if need
            let videoSize = track.naturalSize
            let viewSize = self.playerView.bounds.size
            let rect = CGRect(origin: .zero, size: videoSize).applying(transform)
            let viewWide = viewSize.width / viewSize.height > 1
            let videoWide = rect.width / rect.height > 1

            if viewWide != videoWide {
                transform = transform.rotated(by: .pi / 2)
            }

            self.preferredTransform = transform
        }
    }
    
    private func load(videoCompostion: AVVideoComposition) {
        guard let currentItem = player.currentItem else {
            return;
        }
        
        currentItem.videoComposition = videoCompostion
    }
    
    private func load(audioMix: AVAudioMix) {
        guard let currentItem = player.currentItem else {
            return;
        }
        
        currentItem.audioMix = audioMix
    }
    
    private func load(filter: FilterProtocol?) {
        guard var filterRenderer = playerView as? FilterViewRenderer else {
            return
        }

        filterRenderer.filter = filter
    }
    
    private func load(layer: CALayer?, videoSize: CGSize) {
        guard let layer = layer, let playerItem = player.currentItem else {
            return
        }
        
        if let syncLayer = synchronizedLayer {
            syncLayer.removeFromSuperlayer()
            self.synchronizedLayer = nil
        }
        
        let frame = layerFrame(playerSize: self.playerView.bounds.size, videoSize: videoSize)
        let scaleWidth = frame.width / layer.bounds.width
        let scaleHeight = frame.height / layer.bounds.height
        
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        layer.transform = CATransform3DScale(layer.transform, scaleWidth, scaleHeight, 1.0);
        
        synchronizedLayer = AVSynchronizedLayer(playerItem: playerItem)
        synchronizedLayer?.frame = frame
        synchronizedLayer?.addSublayer(layer)
        playerView.layer.addSublayer(synchronizedLayer!)
    }
    
    private func layerFrame(playerSize: CGSize, videoSize: CGSize) -> CGRect {
        
        let playerRatio = playerSize.width / playerSize.height
        let videoRatio = videoSize.width / videoSize.height
        
        let frame: CGRect
        if playerRatio >= videoRatio {
            let height = playerSize.height
            let width = videoRatio * height
            frame = CGRect(x: (playerSize.width - width) / 2, y: 0, width: width, height: height)
        } else {
            let width = playerSize.width
            let height = width / videoRatio
            frame = CGRect(x: 0, y: (playerSize.height - height) / 2, width: width, height: height)
        }
        
        return frame
    }
}

// MARK: - Observation

extension Player {
 
    private func startObserving(player: AVPlayer) {
        guard !isObserving else { return }

        playerStatusToken = player.observe(\.status, options: [.new]) { [weak self] player, change in
            self?.playStatusChanged()
        }

        playerItemStatusToken = player.observe(\.currentItem?.status, options: [.new]) { [weak self] player, change in
            self?.playStatusChanged()
        }

        if let currentItem = player.currentItem {
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
        }
        
        isObserving = true
    }
    
    private func stopObserving(player: AVPlayer) {
        guard isObserving else { return }

        playerStatusToken?.invalidate()
        playerItemStatusToken?.invalidate()
        
        if let currentItem = player.currentItem {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: currentItem)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
        
        isObserving = false
    }
    
    private func removeTimeObserver(from player: AVPlayer) {
        
        if let timeObserverToken = Constant.timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        
        Constant.timeObserverToken = nil
    }
    
    private func addTimeObserver(from player: AVPlayer) {
        
        removeTimeObserver(from: player)
        
        player.actionAtItemEnd = .pause
        let interval = CMTime(seconds: 0.1, preferredTimescale: Defaults.preferredTimescale)
        Constant.timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time in
            guard let sSelf = self else {
                return
            }
            
            // sync time progress
            var seconds = time.seconds
            if seconds.isInfinite {
                seconds = 0
            }
            
            self?.delegate?.player(sSelf, playerView: sSelf.playerView, progress: min(1.0, Float(seconds / sSelf.duration)))
        }
    }

    @objc
    private func playerItemDidPlayToEndTime(_ notification: Notification) {
        status = .playToEndTime
        delegate?.player(self, playerViewDidPlayToEndTime: playerView)
    }

    private func playStatusChanged() {

        guard let playerItem = player.currentItem else { return }

        if case .readyToPlay = playerItem.status, case .readyToPlay = player.status {
            status = .readyToPlay
        } else if case .failed = playerItem.status {
            status = .failed
            delegate?.player(self, playerView: playerView, didFailWith: playerItem.error ?? player.error)
        } else if case .unknown = player.status {
            status = .unknown
        }
    }
}

// MARK: - AVPlayerItemOutputPullDelegate

extension Player: AVPlayerItemOutputPullDelegate {
    
    public func outputMediaDataWillChange(_ sender: AVPlayerItemOutput) {
        // Restart display link.
        DispatchQueue.main.async {
            self.displayLink.isPaused = false
        }
    }
    
    public func outputSequenceWasFlushed(_ output: AVPlayerItemOutput) {
        // video layer flush
        DispatchQueue.main.async {
            guard let playerView = self.playerView as? SampleBufferDisplayView else {
                return
            }
            playerView.videoLayer.controlTimebase = self.player.currentItem!.timebase
            playerView.videoLayer.flush()
        }
    }
}

// MARK: - DisplayLinkProtocol

extension Player: DisplayLinkProtocol {
    
    func tick(_ displayLink: CADisplayLink) {
        /*
         The callback gets called once every Vsync.
         Using the display link's timestamp and duration we can compute the next time the screen will be refreshed, and copy the pixel buffer for that time
         This pixel buffer can then be processed and later rendered on screen.
         */

        // Calculate the nextVsync time which is when the screen will be refreshed next.
        let nextVSync = displayLink.timestamp + displayLink.duration

        render(at: nextVSync)
    }
}

// MARK: - Render

extension Player {

    private func render(at time: TimeInterval) {

        let itemTime = videoOutput.itemTime(forHostTime: time)

        var presentationItemTime = CMTime.zero

        guard videoOutput.hasNewPixelBuffer(forItemTime: itemTime), let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: &presentationItemTime)  else {

            if displayLink.timestamp - lastTimestamp > 0.5 {
                displayLink.isPaused = true
                videoOutput.requestNotificationOfMediaDataChange(withAdvanceInterval: Constant.oneFrameDuration)
            }

            return
        }

        lastTimestamp = displayLink.timestamp
        playerView.setPreferredTransform(preferredTransform)
        playerView.display(pixelBuffer: pixelBuffer, atTime: presentationItemTime)
    }

}

// MARK: - PreviewerDelegate

public protocol PlayerDelegate : class {
    
    func player(_ player: Player, playerView: PlayerView, didFailWith error: Error?)
    
    func player(_ player: Player, playerView: PlayerView, statusDidChange status: PlayerStatus)
    
    func player(_ player: Player, playerView: PlayerView, progress: Float)
    
    func player(_ player: Player, playerView: PlayerView, durationDidChange duration: Float)
    
    func player(_ player: Player, playerView: PlayerView, presentationSizeDidChange presentationSize: CGSize)
    
    func player(_ player: Player, playerViewDidPlayToEndTime: PlayerView)
}
