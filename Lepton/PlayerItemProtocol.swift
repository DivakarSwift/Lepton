//
//  PlayerItemProtocol.swift
//  Lepton
//
//  Created by bl4ckra1sond3tre on 20/05/2018.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import AVFoundation

public protocol PlayerItemProtocol {

    var composition: AVComposition { get }

    var videoComposition: AVVideoComposition { get }

    var audioMix: AVAudioMix { get }

    var filter: FilterProtocol? { get }

    var overlayLayer: CALayer? { get }
}
