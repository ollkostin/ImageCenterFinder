//
//  ViewController.swift
//  image_center
//
//  Created by Владимир Костин on 19.04.2020.
//  Copyright © 2020 kostin. All rights reserved.
//

import UIKit
import AVFoundation

class ImageCenterViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var session: AVCaptureSession!
    private var device: AVCaptureDevice!
    private var output: AVCaptureVideoDataOutput!

    private let centerFinderService = ImageProcessingService()

    private let resolution = AVCaptureSession.Preset.hd1280x720

    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var trackingButton: UIButton!
    @IBOutlet weak var cameraSegmentControl: UISegmentedControl!
    
    @IBAction func trackingActionButton(_ sender: Any) {
        let state = self.centerFinderService.updateAndGetTrackingState()
        let buttonText: String
        switch state {
        case .disabled:
            buttonText = "Start"
            break
        case .enabled:
            buttonText = "Stop"
        }
        trackingButton.setTitle(buttonText, for: .normal)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.cameraSegmentControl.addTarget(self, action: #selector(cameraSelector), for: .valueChanged)
        self.requestDeviceAndStartSession(camera: .back, resolution: self.resolution)
    }

    override var shouldAutorotate: Bool {
        false
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Convert a captured image buffer to UIImage.
        guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("could not get a pixel buffer")
            return
        }
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        let image = CIImage(cvPixelBuffer: buffer).oriented(.right)

        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)

        let capturedImage = UIImage(ciImage: image)
        DispatchQueue.main.async(execute: {
            self.cameraView.image = self.centerFinderService.process(image: capturedImage)
        })
    }

    func requestDeviceAndStartSession(camera position: AVCaptureDevice.Position, resolution sessionPreset: AVCaptureSession.Preset) {
        self.session = AVCaptureSession()

        self.session.sessionPreset = sessionPreset

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: position) else {
            print("no device")
            return
        }
        self.device = device

        do {
            let input = try AVCaptureDeviceInput(device: self.device)
            self.session.addInput(input)
        } catch {
            print("no device input")
            return
        }

        self.output = AVCaptureVideoDataOutput()
        self.output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        let queue: DispatchQueue = DispatchQueue(label: "videocapturequeue", attributes: [])
        self.output.setSampleBufferDelegate(self, queue: queue)
        self.output.alwaysDiscardsLateVideoFrames = true

        if self.session.canAddOutput(self.output) {
            self.session.addOutput(self.output)
        } else {
            print("could not add a session output")
            return
        }

        do {
            try self.device.lockForConfiguration()
            self.device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 20) // 20 fps
            self.device.unlockForConfiguration()
        } catch {
            print("could not configure a device")
            return
        }

        self.session.startRunning()
    }
    
    @objc fileprivate func cameraSelector(_ sender: UISegmentedControl) {
        let camera: AVCaptureDevice.Position
        switch sender.selectedSegmentIndex {
        case 0:
            camera = .back
            break
        case 1:
            camera = .front
            break
        default:
            camera = .unspecified
            break
        }
        self.requestDeviceAndStartSession(camera: camera, resolution: self.resolution)
    }
}
