//
//  PlayerViewController.swift
//  Visual
//
//  Created by bl4ckra1sond3tre on 2018/5/28.
//  Copyright © 2018 blessingsoftware. All rights reserved.
//

import UIKit
import Lepton

class PlayerViewController: UIViewController {

    var player: Player? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        view.backgroundColor = UIColor.red
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("viewDidAppear")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        print("viewWillDisappear")
    }
}
