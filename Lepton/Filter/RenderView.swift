//
//  RenderView.swift
//  Lepton
//
//  Created by k on 2018/05/26.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

public class RenderView: UIView, FilterRenderer {
    
    public var filter: FilterProtocol?

    var preferredTransform: CGAffineTransform = .identity

    private var ciImage: CIImage? = nil
    private var imageTime: Float64 = 0.0

    private lazy var renderContext: RenderContext? = {

        guard let cgContext = UIGraphicsGetCurrentContext() else {
            return nil
        }

        return RenderContext(cgContext: cgContext)
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func display(pixelBuffer: CVPixelBuffer, atTime time: CMTime) {
        ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        imageTime = CMTimeGetSeconds(time)

        setNeedsDisplay()
    }

    public func setPreferredTransform(_ transform: CGAffineTransform) {
        preferredTransform = transform
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let renderContext = renderContext, let image = renderredImage(in: rect) else {
            return
        }

        var drawOrigin = CGPoint.zero

        switch renderMode {
        case .none:
            break
        case .resize:
            assert(rect.size == image.extent.size, "Resize image first")
        case .aspectFill, .aspectFit:
            if image.extent.width == rect.width {
                drawOrigin.x = 0
                drawOrigin.y = (rect.height - image.extent.height) / 2
            } else if image.extent.height == rect.height {
                drawOrigin.x = (rect.width - image.extent.width) / 2
                drawOrigin.y = 0
            } else {
                assertionFailure("Resize image first")
            }
        }

        let drawRect = CGRect(origin: drawOrigin, size: image.extent.size)

        renderContext.context.draw(image, in: drawRect, from: image.extent)
    }

    private func renderredImage(in rect: CGRect) -> CIImage? {

        guard let ciImage = ciImage else {
            return nil
        }

        let image = resized(image: ciImage.oriented(forExifOrientation: 4), to: rect, with: renderMode)

        guard let filter = filter else {
            return image
        }

        return filter.image(by: image, at: imageTime)
    }
}
