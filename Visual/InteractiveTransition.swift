//
//  InteractiveTransition.swift
//  Visual
//
//  Created by bl4ckra1sond3tre on 2018/5/28.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import UIKit

public struct InteractiveDirection: OptionSet {

    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let top = InteractiveDirection(rawValue: 1 << 0)

    public static let left = InteractiveDirection(rawValue: 1 << 1)

    public static let bottom = InteractiveDirection(rawValue: 1 << 2)

    public static let right = InteractiveDirection(rawValue: 1 << 3)
}

public class InteractiveTransition: UIPercentDrivenInteractiveTransition {

    public var interacting = false

    public var directions: [InteractiveDirection] = [.bottom, .right]

    private weak var viewController: UIViewController?

    public func add(to viewController: UIViewController) {
        self.viewController = viewController

        add(to: viewController.view)
    }

    private func add(to view: UIView) {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(InteractiveTransition.handlePanGesture(_:)))
        view.addGestureRecognizer(gestureRecognizer)
    }

    @objc
    private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {

        switch recognizer.state {

        case .began:
            interacting = true
            viewController?.dismiss(animated: true, completion: nil)

        case .changed:
            guard let view = recognizer.view else {
                return
            }

            let translation = recognizer.translation(in: view)
            let progress = distance(of: translation, in: view)

            update(progress)

        case .cancelled, .ended:
            interacting = false

            guard let view = recognizer.view else {
                return
            }

            let translation = recognizer.translation(in: view)
            let progress = distance(of: translation, in: view)

            if progress > 0.5 || speed(of: recognizer.velocity(in: view)) > 1000.0 {
                finish()
            } else {
                cancel()
            }

        default:
            break
        }
    }

    private func distance(of translation: CGPoint, in view: UIView) -> CGFloat {

        let bottom = directions.contains(.bottom) ? translation.y / view.bounds.height : 0
        let top = directions.contains(.top) ? -translation.y / view.bounds.height : 0
        let right = directions.contains(.right) ? translation.x / view.bounds.width : 0
        let left = directions.contains(.left) ? -translation.x / view.bounds.width : 0

        return max(bottom, top, right, left)
    }

    private func speed(of velocity: CGPoint) -> CGFloat {
        let bottom = directions.contains(.bottom) ? velocity.y : 0
        let top = directions.contains(.top) ? -velocity.y : 0
        let right = directions.contains(.right) ? velocity.x : 0
        let left = directions.contains(.left) ? -velocity.x : 0

        return max(bottom, top, right, left)
    }
}
