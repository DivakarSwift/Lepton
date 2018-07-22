//
//  FilterRenderer.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 2018/6/16.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import Foundation

public class FilterRenderer: Renderer {

    private var context: CIContext?

    private var filter: FilterProtocol

    private var bufferPool: CVPixelBufferPool?

    private var bufferPoolAuxAttributes: NSDictionary

    private var colorSpace: CGColorSpace?

    init?(filter: FilterProtocol) {
        guard let eaglContext = EAGLContext(api: .openGLES2) else {
            return nil
        }

        self.context = CIContext(eaglContext: eaglContext, options: [CIContextOption.workingColorSpace: NSNull()])
        self.filter = filter

        let maxRetainedBufferCount: Int32 = 4
        guard let bufferPool = createPixelBufferPoll(width: 0, height: 0, pixelFormat: kCVPixelFormatType_32BGRA, maxBufferCount: maxRetainedBufferCount) else {
            return nil
        }

        let bufferPoolAuxAttributes = createPixelBufferPoolAuxAttribute(maxBufferCount: maxRetainedBufferCount)
        preallocatePixelBuffers(in: bufferPool, auxAttributes: bufferPoolAuxAttributes)

        self.bufferPool = bufferPool
        self.bufferPoolAuxAttributes = bufferPoolAuxAttributes
    }

    deinit {
        deleteBuffers()
    }

    // MARK: - Renderer

    public var inputPixelFormat: FourCharCode {
        return kCVPixelFormatType_32BGRA
    }

    public func reset() {
        deleteBuffers()
    }

    public func copyRenderedPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        guard let context = context, let bufferPool = bufferPool else {
            return pixelBuffer
        }

        var renderedOutputPixelBuffer: CVPixelBuffer?

        let sourceImage = CIImage(cvPixelBuffer: pixelBuffer)

        let filteredImage = filter.image(by: sourceImage)

        let err = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, bufferPool, &renderedOutputPixelBuffer)

        guard err == kCVReturnSuccess, let renderedPixelBuffer = renderedOutputPixelBuffer else {
            return pixelBuffer
        }

        context.render(filteredImage, to: renderedPixelBuffer, bounds: filteredImage.extent, colorSpace: colorSpace)

        return renderedPixelBuffer
    }

    private func deleteBuffers() {
        bufferPool = nil
        bufferPoolAuxAttributes = [:]
        context = nil
        colorSpace = nil
    }
}
