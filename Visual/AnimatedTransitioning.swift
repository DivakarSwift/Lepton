//
//  AnimatedTransitioning.swift
//  Visual
//
//  Created by bl4ckra1sond3tre on 2018/5/28.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import UIKit

public class AnimatedTransitioning: NSObject {

    let duration: TimeInterval

    var interactiveTransition: InteractiveTransition?

    let animation: TransitionAnimation

    public init(duration: TimeInterval, animation: TransitionAnimation) {
        self.duration = duration
        self.animation = animation
        super.init()
    }
}

extension AnimatedTransitioning: UIViewControllerTransitioningDelegate {

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TransitionAnimator(transitionType: .present, duration: duration, animation: animation)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return TransitionAnimator(transitionType: .dismiss, duration: duration, animation: animation)
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let interactiveTransition = interactiveTransition else {
            return nil
        }
        return interactiveTransition.interacting ? interactiveTransition : nil
    }
}
