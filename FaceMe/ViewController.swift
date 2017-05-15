//
//  ViewController.swift
//  FaceMe
//
//  Created by yejiongtao on 14/05/2017.
//  Copyright © 2017 yejiongtao. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController {

    @IBOutlet var previewView: GPUImageView!
    
    var videoCamera: GPUImageVideoCamera?
    var filter: GPUImageFilter?
    
    var leftEye: CGRect?
    var rightEye: CGRect?
    var imageView1: UIImageView?
    var imageView2: UIImageView?
    var shouldUpdateLeftEye = false
    var shouldUpdateRightEye = false
    
    lazy var context: CIContext = {
        return CIContext()
    }()
    var faceDetector: CIDetector?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPresetHigh, cameraPosition: .front)
        self.videoCamera!.outputImageOrientation = .portrait;
        self.videoCamera?.horizontallyMirrorFrontFacingCamera = true
        
        // setup filter
//        self.filter = GPUImagePixellateFilter()
//        self.filter = GPUImageHueFilter()
//        self.filter = GPUImageFilter()        // an empty filter
//        
//        self.videoCamera?.addTarget(filter)
//        self.filter?.addTarget(self.previewView as GPUImageView)
//        self.videoCamera?.startCapture()
        
        
        
//        filter = GPUImageFilter()
//        videoCamera?.addTarget(filter)
//        let blendFilter = GPUImageAlphaBlendFilter()
//        blendFilter.mix = 1
//        
//        let tmpView = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 800))
//        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 40))
//        label.font = UIFont.systemFont(ofSize: 17)
//        label.text = "Hello Tau"
//        label.backgroundColor = UIColor.clear
//        label.textColor = UIColor.black
//        tmpView.addSubview(label)
//        
//        let uiElementInput = GPUImageUIElement(view: tmpView)
//        filter?.addTarget(blendFilter)
//        uiElementInput?.addTarget(blendFilter)
//        blendFilter.addTarget(previewView)
//        
//        filter?.frameProcessingCompletionBlock = { (_: GPUImageOutput?, _: CMTime) in
//            uiElementInput?.update()
//        }
//        
//        self.videoCamera?.startCapture()
//        
        
        self.filter = GPUImageFilter()
        let blendFilter = GPUImageAlphaBlendFilter()
        blendFilter.mix = 0.5
        
        let tmpView = UIView(frame: self.view.frame)
        imageView1 = UIImageView(frame: CGRect(x: 100, y: 100, width: 50, height: 50))
        imageView1?.image = #imageLiteral(resourceName: "Star")
        tmpView.addSubview(imageView1!)
        imageView2 = UIImageView(frame: CGRect(x: 100, y: 100, width: 50, height: 50))
        imageView2?.image = #imageLiteral(resourceName: "Star")
        tmpView.addSubview(imageView2!)
        
        let uiElementInput = GPUImageUIElement(view: tmpView)
        
        videoCamera?.addTarget(filter)
        filter?.addTarget(blendFilter)
        uiElementInput?.addTarget(blendFilter)  // the order of adding to blendFilter matters
        blendFilter.addTarget(previewView)
        
        self.setupface()
        
        filter?.frameProcessingCompletionBlock = { (output: GPUImageOutput?, _: CMTime) in
            if let image = output?.newCGImageFromCurrentlyProcessedOutput() {
                self.updateFace(ofImage: CIImage(cgImage: image.takeUnretainedValue()),
                                sizeOfPoint: self.previewView.frame.size)
//                print(image.takeUnretainedValue().width, image.takeUnretainedValue().height)
            }
            
            if self.shouldUpdateLeftEye {
                if self.leftEye != nil {
                    self.imageView1?.frame = self.leftEye!
                } else {
                    self.imageView1?.frame = CGRect(x: -100, y: -100, width: 50, height: 50)
                }
                self.shouldUpdateLeftEye = false;
            }
            
            if self.shouldUpdateRightEye {
                if self.rightEye != nil {
                    self.imageView2?.frame = self.rightEye!
                }else {
                    self.imageView2?.frame = CGRect(x: -100, y: -100, width: 50, height: 50)
                }
                self.shouldUpdateRightEye = false
            }
                       
            
            uiElementInput?.update()
        }

        self.videoCamera?.startCapture()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupface() {
        faceDetector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: context,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
    }
    
    private func updateFace(ofImage image: CIImage, sizeOfPoint: CGSize) {
        let features = faceDetector?.features(in: image) as! [CIFaceFeature]
        let size = CGSize(width: image.extent.width, height: image.extent.height)
        let minDiff: CGFloat = 20.0
        
        if features.count == 0 {
            self.leftEye = nil
            self.rightEye = nil
            shouldUpdateLeftEye = true
            shouldUpdateRightEye = true
        }
        
        for faceFeature in features {
            if (faceFeature.hasLeftEyePosition) {
                let pos = convertPoint(fromPoint: faceFeature.leftEyePosition, fromSize: size, toSize: sizeOfPoint)
                if self.leftEye == nil ||
                    fabs(pos.x-25 - (self.leftEye?.origin.x)!) > minDiff ||
                    fabs(pos.y-25 - (self.leftEye?.origin.y)!) > minDiff {
                    self.shouldUpdateLeftEye = true
                    self.leftEye = CGRect(x: pos.x-25, y: pos.y-25, width: 50, height: 50)
                }
            }
            
            if (faceFeature.hasRightEyePosition) {
                let pos = convertPoint(fromPoint: faceFeature.rightEyePosition, fromSize: size, toSize: sizeOfPoint)
                if self.rightEye == nil ||
                    fabs(pos.x-25 - (self.rightEye?.origin.x)!) > minDiff ||
                    fabs(pos.y-25 - (self.rightEye?.origin.y)!) > minDiff {
                    self.shouldUpdateRightEye = true
                    self.rightEye = CGRect(x: pos.x-25, y: pos.y-25, width: 50, height: 50)
                }
            }
            
        }
    }
    
    private func convertPoint(fromPoint : CGPoint, fromSize: CGSize, toSize: CGSize) -> CGPoint {
        return CGPoint(x: fromPoint.x * toSize.width / fromSize.width,
                       y: toSize.height - fromPoint.y * toSize.height / fromSize.height)
    }
}

