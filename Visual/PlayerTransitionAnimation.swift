//
//  PlayerTransitionAnimation.swift
//  Visual
//
//  Created by bl4ckra1sond3tre on 2018/5/31.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import UIKit
import Lepton

public class PlayerTransitionAnimation: TransitionAnimation {

    public let initialFrame: CGRect
    public let finalFrame: CGRect
    public let player: Player

    public init(initialFrame: CGRect, finalFrame: CGRect, player: Player) {
        self.initialFrame = initialFrame
        self.finalFrame = finalFrame
        self.player = player
    }

    public func startAnimate(withType transitionType: TransitionType, containerView: UIView) {
        player.playerView.removeFromSuperview()
        switch transitionType {
        case .present:
            player.playerView.frame = initialFrame
            containerView.addSubview(player.playerView)
        case .dismiss:
            player.playerView.frame = finalFrame
            containerView.addSubview(player.playerView)
        }
    }

    public func animate(withType transitionType: TransitionType, duration: TimeInterval, toView: UIView, completion: ((Bool) -> Void)?) {

        toView.alpha = transitionType == .present ? 0.0 : 1.0

        let frame = transitionType == .present ? self.finalFrame : self.initialFrame

        UIView.animate(withDuration: duration, animations: {
            self.player.playerView.frame = frame
        }, completion: { finished in
            toView.alpha = 1.0
            completion?(finished)
        })
    }

    public func finishAnimate(withType transitionType: TransitionType, toView: UIView, completion: Bool) {

        player.playerView.removeFromSuperview()

        switch transitionType {
        case .present:
            player.playerView.frame = completion ? finalFrame : initialFrame
        case .dismiss:
            player.playerView.frame = completion ? initialFrame : finalFrame
        }

        toView.addSubview(player.playerView)
    }
}
