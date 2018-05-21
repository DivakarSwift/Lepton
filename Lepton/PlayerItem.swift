//
//  PreviewerItem.swift
//  Photon
//
//  Created by bl4ckra1sond3tre on 20/05/2018.
//  Copyright © 2018 blessingsoft. All rights reserved.
//

import AVFoundation

public protocol FilterProtocol {

    var filter: CIFilter { get }
}

public enum PlayerItemStatus {
    case unknown
    case readyToPlay
    case play
    case pause
    case playToEndTime
    case failed
}

public struct PlayerItem: Playable {
    
    public let composition: AVComposition
    
    public let videoComposition: AVVideoComposition
    
    public let audioMix: AVAudioMix
    
    public let filter: FilterProtocol?

    public let overlayLayer: CALayer?

    public var status: PlayerItemStatus = .unknown
    
    public init(composition: AVComposition, videoComposition: AVVideoComposition, audioMix: AVAudioMix, filter: FilterProtocol? = nil, overlayLayer: CALayer? = nil) {
        self.composition = composition
        self.videoComposition = videoComposition
        self.audioMix = audioMix
        self.filter = filter
        self.overlayLayer = overlayLayer
    }
}
