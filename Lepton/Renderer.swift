//
//  Renderer.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 2018/5/26.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import CoreMedia

public enum RenderMode {
    case none
    case resize
    case aspectFill
    case aspectFit
}

public protocol Renderer {

    var renderMode: RenderMode { get }

    func setPreferredTransform(_ transform: CGAffineTransform)

    func display(pixelBuffer: CVPixelBuffer, atTime time: CMTime)
}

extension Renderer {

    public var renderMode: RenderMode {
        return .aspectFit
    }

    public func resized(image: CIImage, to rect: CGRect, with mode: RenderMode) -> CIImage {

        let imageSize = image.extent.size

        var horizontalScale = rect.size.width / imageSize.width
        var verticalScale = rect.size.height / imageSize.height

        switch mode {
        case .none:
            return image
        case .resize:
            break
        case .aspectFill:
            horizontalScale = max(horizontalScale, verticalScale)
            verticalScale = horizontalScale
        case .aspectFit:
            horizontalScale = min(horizontalScale, verticalScale)
            verticalScale = horizontalScale
        }

        return image.transformed(by: CGAffineTransform(scaleX: horizontalScale, y: verticalScale))
    }
}

public protocol FilterRenderer: Renderer {

    var filter: FilterProtocol? { get set }
}
