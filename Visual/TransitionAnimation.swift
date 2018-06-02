//
//  TransitionAnimation.swift
//  Visual
//
//  Created by bl4ckra1sond3tre on 2018/6/2.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import UIKit

public protocol TransitionAnimation {

    var initialFrame: CGRect { get }
    var finalFrame: CGRect { get }

    func startAnimate(withType transitionType: TransitionType, containerView: UIView)

    func animate(withType transitionType: TransitionType, duration: TimeInterval, toView: UIView, completion: ((Bool) -> Void)?)

    func finishAnimate(withType transitionType: TransitionType, toView: UIView, completion: Bool)
}

extension TransitionAnimation {

    public func animate(withType transitionType: TransitionType, duration: TimeInterval, using transitionContext: UIViewControllerContextTransitioning, completion: ((Bool) -> Void)?) {

        UIApplication.shared.beginIgnoringInteractionEvents()

        guard let viewController = transitionContext.viewController(forKey: transitionType == .present ? .to : .from) else {
            return
        }

        let finalFrame = transitionContext.finalFrame(for: viewController)

        UIView.animate(withDuration: duration, animations: {
            viewController.view.frame = finalFrame
        }, completion: { finished in
            UIApplication.shared.endIgnoringInteractionEvents()
            completion?(finished)
        })
    }
}
