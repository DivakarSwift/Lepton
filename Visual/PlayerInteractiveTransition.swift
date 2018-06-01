//
//  PlayerInteractiveTransition.swift
//  Visual
//
//  Created by bl4ckra1sond3tre on 2018/5/28.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import UIKit

class PlayerInteractiveTransition: UIPercentDrivenInteractiveTransition {

    var interacting = false

    weak var viewController: UIViewController?

    func add(to viewController: UIViewController) {
        self.viewController = viewController

        add(to: viewController.view)
    }

    private func add(to view: UIView) {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(PlayerInteractiveTransition.handlePanGesture(_:)))
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

            let progress = recognizer.translation(in: view).y / view.bounds.height

            update(progress)

        case .cancelled, .ended:
            interacting = false

            guard let view = recognizer.view else {
                return
            }

            let progress = recognizer.translation(in: view).y / view.bounds.height

            let velocity = recognizer.velocity(in: view).x

            if progress > 0.5 || velocity > 1000.0 {
                finish()
            } else {
                cancel()
            }

        default:
            break
        }
    }
}
