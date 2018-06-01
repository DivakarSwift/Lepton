//
//  RenderContext.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 2018/5/26.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import CoreGraphics

struct RenderContext {

    let context: CIContext

    init(cgContext: CGContext) {
        self.context = CIContext(cgContext: cgContext)
    }
}
