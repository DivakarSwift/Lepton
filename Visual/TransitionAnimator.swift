//
//  TransitionAnimator.swift
//  Visual
//
//  Created by bl4ckra1sond3tre on 2018/5/28.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import UIKit

public enum TransitionType {
    case present
    case dismiss
}

public class TransitionAnimator: NSObject {

    private let duration: TimeInterval

    private let transitionType: TransitionType

    private let animation: TransitionAnimation

    public init(transitionType: TransitionType, duration: TimeInterval, animation: TransitionAnimation) {
        self.transitionType = transitionType
        self.duration = duration
        self.animation = animation
        
        super.init()
    }
}

extension TransitionAnimator: UIViewControllerAnimatedTransitioning {

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(toView)

        animation.startAnimate(withType: transitionType, containerView: containerView)

        animation.animate(withType: transitionType, duration: duration, toView: toView) { finished in
            let completion = finished && !transitionContext.transitionWasCancelled
            
            if !completion {
                toView.removeFromSuperview()
            }

            guard let view = transitionContext.view(forKey: completion ? .to : .from) else {
                return
            }

            self.animation.finishAnimate(withType: self.transitionType, toView: view, completion: completion)

            transitionContext.completeTransition(completion)
        }
    }
}
