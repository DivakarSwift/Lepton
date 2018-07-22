//
//  PixelBuffer.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 2018/6/17.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import CoreVideo

func createPixelBufferPoll(width: Int32, height: Int32, pixelFormat: OSType, maxBufferCount: Int32) -> CVPixelBufferPool? {
    var outputPool: CVPixelBufferPool?

    let sourcePixelBufferOptions: NSDictionary = [
        kCVPixelBufferPixelFormatTypeKey: pixelFormat,
        kCVPixelBufferWidthKey: width,
        kCVPixelBufferHeightKey: height,
        kCVPixelFormatOpenGLESCompatibility: true,
        kCVPixelBufferIOSurfacePropertiesKey: NSDictionary()
    ]

    let pixelBufferPoolOptions: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey: maxBufferCount]

    CVPixelBufferPoolCreate(kCFAllocatorDefault, pixelBufferPoolOptions, sourcePixelBufferOptions, &outputPool)

    return outputPool
}

func createPixelBufferPoolAuxAttribute(maxBufferCount: Int32) -> NSDictionary {
    let auxAttributes: NSDictionary = [kCVPixelBufferPoolAllocationThresholdKey: maxBufferCount]
    return auxAttributes
}

func preallocatePixelBuffers(in bufferPool: CVPixelBufferPool, auxAttributes: NSDictionary) {
    // Preallocate buffers in the pool, since this is for real-time display/capture
    var pixelBuffers: [CVPixelBuffer] = []
    while true {
        var pixelBuffer: CVPixelBuffer?
        let err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, bufferPool, auxAttributes, &pixelBuffer)

        if err == kCVReturnWouldExceedAllocationThreshold {
            break
        }
        assert(err == noErr)

        if let pixelBuffer = pixelBuffer {
            pixelBuffers.append(pixelBuffer)
        }
    }

    pixelBuffers.removeAll()
}
