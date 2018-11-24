//
//  ViewController.swift
//  CreateML_Example
//
//  Created by Eduardo Lombardi on 23/11/18.
//  Copyright © 2018 Eduardo Lombardi. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet private weak var uiRecognitionLabel: UILabel?
    @IBOutlet private weak var uiSwitch: UISwitch?
    @IBOutlet private weak var uiCameraView: UIView?
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

}

