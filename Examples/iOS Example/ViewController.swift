//
//  ViewController.swift
//  iOS Example
//
//  Created by Yvo van Beek on 5/17/17.
//  Copyright © 2017 Building42. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  var demo: TelegraphDemo!

  override func viewDidLoad() {
    super.viewDidLoad()

    demo = TelegraphDemo()
    demo.start()
  }
}
