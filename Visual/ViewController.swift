//
//  ViewController.swift
//  Visual
//
//  Created by bl4ckra1sond3tre on 20/05/2018.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import UIKit
import Lepton
import AVFoundation

class ViewController: UIViewController {

    var player: Player = Player()

    var asset: AVURLAsset?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        player.playerView.frame = CGRect(x: 20, y: 200, width: view.bounds.width - 40, height: view.bounds.height - 400)
        player.delegate = self
        player.isAutoPlay = false

        let videoURL = URL(fileURLWithPath: Bundle.main.path(forResource: "1", ofType: "M4V")!)
        let asset = AVURLAsset(url: videoURL)

        asset.loadValuesAsynchronously(forKeys: ["duration", "tracks"]) { [unowned self] in

            let composition = AVMutableComposition()

            guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                return
            }

            let timeRange = CMTimeRange(start: CMTime.zero, duration: self.asset!.duration)

            guard let track = self.asset!.tracks(withMediaType: .video).first else {
                return
            }

            try? videoTrack.insertTimeRange(timeRange, of: track, at: CMTime.zero)

            let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
            videoComposition.renderSize = track.naturalSize
            videoComposition.frameDuration = CMTime(seconds: 1, preferredTimescale: 30)
            let audioMix = AVMutableAudioMix()

            let playerItem = PlayerItem(composition: composition, videoComposition: videoComposition, audioMix: audioMix, filter: Filter(type: .instant))

            self.player.load(item: playerItem)
        }

        self.asset = asset

        view.addSubview(player.playerView)
    }

    var transitioning: AnimatedTransitioning?

    @IBAction func play(_ sender: Any) {
        player.play()

        let vc = PlayerViewController()

        let animation = PlayerTransitionAnimation(initialFrame: player.playerView.frame, finalFrame: view.frame, player: player)
        transitioning = AnimatedTransitioning(duration: 0.30, animation: animation)
        let interectiveTransition = InteractiveTransition()
        interectiveTransition.directions = [.top, .left, .bottom, .right]

        interectiveTransition.add(to: vc)
        transitioning?.interactiveTransition = interectiveTransition

        vc.transitioningDelegate = transitioning

        navigationController?.present(vc, animated: true, completion: nil)
    }
}

extension ViewController: PlayerDelegate {

    func player(_ player: Player, playerViewDidReachEnd: PlayerView) {
        print(#function)
    }

    func player(_ player: Player, playerView: PlayerView, progress: Float) {
        print("player process: \(progress)")
    }

    func player(_ player: Player, playerView: PlayerView, didFailWith error: Error?) {
        print("player did fail with error: \(String(describing: error))")
    }

    func player(_ player: Player, playerView: PlayerView, durationDidChange duration: Float) {
        print("player duration did change: \(duration)")
    }

    func player(_ player: Player, playerView: PlayerView, statusDidChange status: PlayerStatus) {
        print("player status did change: \(status)")
    }

    func player(_ player: Player, playerView: PlayerView, presentationSizeDidChange presentationSize: CGSize) {
        print("player presentation size did change: \(presentationSize)")
    }
}

