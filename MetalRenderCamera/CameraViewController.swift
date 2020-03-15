//
//  ViewController.swift
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 24/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

import UIKit
import Metal
import AudioToolbox
import AVFoundation

internal final class CameraViewController: MTKViewController {
    var session: MetalCameraSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session = MetalCameraSession(delegate: self)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.numberOfTouchesRequired = 1
        tap.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tap)
        
        let tapTwo = UITapGestureRecognizer(target: self, action: #selector(handleTapTwo))
        tapTwo.numberOfTouchesRequired = 2
        tapTwo.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapTwo)
        
        let tapThree = UITapGestureRecognizer(target: self, action: #selector(handleTapThree))
        tapThree.numberOfTouchesRequired = 3
        tapThree.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tapThree)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
        session?.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        session?.stop()
    }
    
    // Take screenshot and save.
    @objc func handleTap(_ gesture: UITapGestureRecognizer){
        
        self.metalView.isPaused = true
        
        AudioServicesPlaySystemSound(1108);
        let bounds = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        self.view.drawHierarchy(in: bounds, afterScreenUpdates: false)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
      
        let shutterView = UIView(frame: view.frame)
        shutterView.backgroundColor = UIColor.white
        view.addSubview(shutterView)
        UIView.animate(withDuration: 0.3, animations: {
            shutterView.alpha = 0
        }, completion: { (_) in
            shutterView.removeFromSuperview()
        })
        
        let activityViewController = UIActivityViewController(activityItems: [img!], applicationActivities: nil)
        
    
        activityViewController.completionWithItemsHandler = { (activityType, completed:Bool, returnedItems:[Any]?, error: Error?) in
            //if completed {
                // Do something
                self.metalView.isPaused = false
            //}
        }
        
        self.present(activityViewController, animated: true)
    }
    
    // Switch cameras.
    @objc func handleTapTwo(_ gesture: UITapGestureRecognizer){

        self.metalView.isPaused = true

        session?.stop()
        
        if (session?.captureDevicePosition == .front) {
            session = MetalCameraSession(pixelFormat: .rgb, captureDevicePosition: .back, delegate: self)
            self.cameraFront = false
        } else {
            session = MetalCameraSession(pixelFormat: .rgb, captureDevicePosition: .front, delegate: self)
            self.cameraFront = true
        }

        session?.start()
        
        let shutterView = UIView(frame: view.frame)
        shutterView.backgroundColor = UIColor.black
        view.addSubview(shutterView)
        shutterView.alpha = 0.0
        UIView.animate(withDuration: 1.0, animations: {
            shutterView.alpha = 1.0
        }, completion: { (_) in
            self.metalView.isPaused = false
            shutterView.removeFromSuperview()
        })
        
    }
    
    // Enable flashlight.
    @objc func handleTapThree(_ gesture: UITapGestureRecognizer){
        
        if (session?.captureDevicePosition == .back) {
            flashlight()
        }
        
    }
    
    // https://stackoverflow.com/a/48741559
    func flashlight() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else{
            return
        }
        if (device.hasTorch) {
            do {
                try device.lockForConfiguration()
                if (device.torchMode == .on) {
                    device.torchMode = .off
                } else {
                    device.torchMode = .on
                    
                }
                device.unlockForConfiguration()
            } catch {
                
                print("Torch could not be used")
                print(error)
            }
        }
        else{
            print("Torch is not available")
        }
    }
    
}

// MARK: - MetalCameraSessionDelegate
extension CameraViewController: MetalCameraSessionDelegate {
    func metalCameraSession(_ session: MetalCameraSession, didReceiveFrameAsTextures textures: [MTLTexture], withTimestamp timestamp: Double) {
        //if (self.textureBlurred == true) {
          self.texture = textures[0]
          //self.textureBlurred = false
        //}
    }
    
    func metalCameraSession(_ cameraSession: MetalCameraSession, didUpdateState state: MetalCameraSessionState, error: MetalCameraSessionError?) {
        
        if error == .captureSessionRuntimeError {
            /**
             *  In this app we are going to ignore capture session runtime errors
             */
            cameraSession.start()
        }
        
        DispatchQueue.main.async { 
            // self.title = "Metal camera: \(state)"
        }
        
        NSLog("Session changed state to \(state) with error: \(error?.localizedDescription ?? "None").")
    }
}
