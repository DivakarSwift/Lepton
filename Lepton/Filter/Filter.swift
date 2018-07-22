//
//  Filter.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 2018/5/26.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import Foundation

public protocol FilterProtocol {

    var filter: CIFilter { get }

    var name: String { get }

    var isEnabled: Bool { get }

    func image(by processingImage: CIImage, at time: Float64) -> CIImage
}

extension FilterProtocol {

    public var isEnabled: Bool {
        return true
    }

    public var name: String {
        return filter.name
    }

    public func image(by processingImage: CIImage, at time: Float64 = 0) -> CIImage {
        guard isEnabled else {
            return processingImage
        }

        filter.setValue(processingImage, forKey: kCIInputImageKey)
        guard let filterrdImage = filter.outputImage else {
            return processingImage
        }

        return filterrdImage
    }
}
