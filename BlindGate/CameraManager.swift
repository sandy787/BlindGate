import AVFoundation
import Vision
import SwiftUI
import CoreML

class CameraManager: NSObject, ObservableObject {
    @Published var current_text = ""
    @Published var isSetup = false
    @Published var detectionBoxes: [DetectionBox] = []
    private(set) var captureSession: AVCaptureSession?
    private var videoOutput = AVCaptureVideoDataOutput()
    private let objectDetector = ObjectDetector.shared
    private var depthDataOutput: AVCaptureDepthDataOutput?
    
    private var currentVideoPixelBuffer: CVPixelBuffer?
    private let processingQueue = DispatchQueue(label: "com.blindgate.processing")
    
    override init() {
        super.init()
        setupAudioSession()
        setupCamera()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .back) ??
              AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) ??
              AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: device)
            
            guard let captureSession = captureSession else { return }
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]
            videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            if device.hasMediaType(.depthData) {
                depthDataOutput = AVCaptureDepthDataOutput()
                depthDataOutput?.setDelegate(self, callbackQueue: processingQueue)
                depthDataOutput?.isFilteringEnabled = true
                
                if captureSession.canAddOutput(depthDataOutput!) {
                    captureSession.addOutput(depthDataOutput!)
                    
                    if let connection = depthDataOutput?.connection(with: .depthData) {
                        connection.isEnabled = true
                    }
                }
            }
            
            if let connection = videoOutput.connection(with: .video) {
                connection.videoOrientation = .portrait
                connection.isEnabled = true
            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession?.startRunning()
                DispatchQueue.main.async {
                    self?.isSetup = true
                }
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    private func processFrame(pixelBuffer: CVPixelBuffer, depthData: AVDepthData?) {
        objectDetector.detect(pixelBuffer: pixelBuffer, depthData: depthData) { [weak self] detectionText, boxes in
            DispatchQueue.main.async {
                self?.current_text = detectionText
                self?.detectionBoxes = boxes
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        currentVideoPixelBuffer = pixelBuffer
        
        if depthDataOutput == nil {
            processFrame(pixelBuffer: pixelBuffer, depthData: nil)
        }
    }
}

extension CameraManager: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        guard let pixelBuffer = currentVideoPixelBuffer else { return }
        processFrame(pixelBuffer: pixelBuffer, depthData: depthData)
    }
} 