//
//  SampleBufferDisplayView.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 20/05/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import UIKit
import AVFoundation

public class SampleBufferDisplayView: UIView, ViewRenderer {

    var videoLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }

    private var videoInfo: CMVideoFormatDescription?

    override public class var layerClass: AnyClass {
        return AVSampleBufferDisplayLayer.self
    }

    public func display(pixelBuffer: CVPixelBuffer, atTime time: CMTime) {

        var err: OSStatus = noErr

        if videoInfo == nil || !CMVideoFormatDescriptionMatchesImageBuffer(videoInfo!, imageBuffer: pixelBuffer) {
            videoInfo = nil

            err = CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, formatDescriptionOut: &videoInfo)
            if (err != noErr) {
                print("Error at CMVideoFormatDescriptionCreateForImageBuffer \(err)")
            }
        }

        guard let info = videoInfo else {
            return
        }

        var sampleTimingInfo = CMSampleTimingInfo(duration: CMTime.invalid, presentationTimeStamp: time, decodeTimeStamp: CMTime.invalid)
        var sampleBuffer: CMSampleBuffer?

        err = CMSampleBufferCreateForImageBuffer(allocator: nil, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: info, sampleTiming: &sampleTimingInfo, sampleBufferOut: &sampleBuffer)
        if (err != noErr) {
            print("Error at CMSampleBufferCreateForImageBuffer \(err)")
        }

        guard let buffer = sampleBuffer, videoLayer.isReadyForMoreMediaData else {
            return
        }

        videoLayer.enqueue(buffer)
    }

    public func flush() {
        //
    }

    public func reset() {
        //
    }

    public func setPreferredTransform(_ transform: CGAffineTransform) {
        //
    }
}
