//
//  Renderer.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 2018/5/26.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import CoreImage
import CoreMedia

public enum RenderMode {
    case none
    case resize
    case aspectFill
    case aspectFit
}

public protocol Renderer {

    var inputPixelFormat: FourCharCode { get } // One of 420f, 420v, or BGRA

    func copyRenderedPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer

    func reset()
}
