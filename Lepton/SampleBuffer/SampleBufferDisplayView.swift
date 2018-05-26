//
//  SampleBufferDisplayView.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 20/05/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import UIKit
import AVFoundation

public class SampleBufferDisplayView: UIView, Renderer {

    var videoLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }

    private var videoInfo: CMVideoFormatDescription?

    override public class var layerClass: AnyClass {
        return AVSampleBufferDisplayLayer.self
    }

    public func display(pixelBuffer: CVPixelBuffer, atTime time: CMTime) {

        var err: OSStatus = noErr

        if videoInfo == nil || !CMVideoFormatDescriptionMatchesImageBuffer(videoInfo!, pixelBuffer) {
            videoInfo = nil

            err = CMVideoFormatDescriptionCreateForImageBuffer(nil, pixelBuffer, &videoInfo)
            if (err != noErr) {
                print("Error at CMVideoFormatDescriptionCreateForImageBuffer \(err)")
            }
        }

        guard let info = videoInfo else {
            return
        }

        var sampleTimingInfo = CMSampleTimingInfo(duration: kCMTimeInvalid, presentationTimeStamp: time, decodeTimeStamp: kCMTimeInvalid)
        var sampleBuffer: CMSampleBuffer?

        err = CMSampleBufferCreateForImageBuffer(nil, pixelBuffer, true, nil, nil, info, &sampleTimingInfo, &sampleBuffer)
        if (err != noErr) {
            print("Error at CMSampleBufferCreateForImageBuffer \(err)")
        }

        guard let buffer = sampleBuffer, videoLayer.isReadyForMoreMediaData else {
            return
        }

        videoLayer.enqueue(buffer)
    }

    public func setPreferredTransform(_ transform: CGAffineTransform) {
        //
    }
}
