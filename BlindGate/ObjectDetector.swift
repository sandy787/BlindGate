import Vision
import CoreML
import AVFoundation
import ARKit

class ObjectDetector: NSObject {
    static let shared = ObjectDetector()
    
    private var visionModel: VNCoreMLModel?
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenObjects: Set<String> = []
    private var lastSpeakTime: [String: Date] = [:]
    private let minimumRepeatInterval: TimeInterval = 3.0 // Minimum seconds between repeating the same object
    private var isCurrentlySpeaking = false
    private let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
    
    struct DetectedObject {
        let identifier: String
        let confidence: Float
        let boundingBox: CGRect
    }
    
    override init() {
        super.init()
        setupModel()
        synthesizer.delegate = self
        impactFeedback.prepare()
    }
    
    private func setupModel() {
        guard let model = try? YOLOv3(configuration: MLModelConfiguration()) else {
            print("Failed to create YOLOv3 model instance")
            return
        }
        
        do {
            visionModel = try VNCoreMLModel(for: model.model)
        } catch {
            print("Failed to create Vision model: \(error)")
        }
    }
    
    private func speakDetections(_ detections: [DetectedObject]) {
        guard !detections.isEmpty else { return }
        
        let currentTime = Date()
        let currentObjects = Set(detections.map { $0.identifier })
        
        // Filter objects that haven't been spoken recently
        let objectsToSpeak = currentObjects.filter { object in
            if let lastTime = lastSpeakTime[object] {
                return currentTime.timeIntervalSince(lastTime) >= minimumRepeatInterval
            }
            return true
        }
        
        // If nothing new to speak and currently speaking, return
        if objectsToSpeak.isEmpty {
            return
        }
        
        // Update last spoken objects and times
        lastSpokenObjects = currentObjects
        
        // Speak new or repeated (after interval) objects
        for object in objectsToSpeak {
            let utterance = AVSpeechUtterance(string: object)
            utterance.rate = 0.6
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            
            // Update last speak time for this object
            lastSpeakTime[object] = currentTime
            
            isCurrentlySpeaking = true
            synthesizer.speak(utterance)
        }
        
        // Clean up old entries from lastSpeakTime
        cleanupOldSpokenObjects(currentTime: currentTime)
    }
    
    private func cleanupOldSpokenObjects(currentTime: Date) {
        // Remove entries older than twice the minimum repeat interval
        let cleanupInterval = minimumRepeatInterval * 2
        lastSpeakTime = lastSpeakTime.filter { object, time in
            currentTime.timeIntervalSince(time) < cleanupInterval
        }
    }
    
    func detect(pixelBuffer: CVPixelBuffer, depthData: AVDepthData?, completion: @escaping (String, [DetectionBox]) -> Void) {
        guard let model = visionModel else {
            print("Vision model not initialized")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Detection error: \(error)")
                return
            }
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                return
            }
            
            let detectedObjects = results
                .filter { $0.confidence > 0.6 }
                .prefix(3)
                .compactMap { observation -> DetectedObject? in
                    guard let label = observation.labels.first else { return nil }
                    return DetectedObject(
                        identifier: label.identifier.capitalized,
                        confidence: label.confidence,
                        boundingBox: observation.boundingBox
                    )
                }
            
            let boxes = detectedObjects.map { object in
                DetectionBox(
                    rect: object.boundingBox,
                    label: object.identifier,
                    confidence: object.confidence
                )
            }
            
            if let depth = depthData {
                self.checkProximityAndVibrate(objects: detectedObjects, depthData: depth)
            }
            
            let detectionText = detectedObjects
                .map { "\($0.identifier) (\(Int($0.confidence * 100))%)" }
                .joined(separator: ", ")
            
            DispatchQueue.main.async {
                self.speakDetections(Array(detectedObjects))
                completion(detectionText, boxes)
            }
        }
        
        request.imageCropAndScaleOption = .scaleFit
        
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
                .perform([request])
        } catch {
            print("Failed to perform detection: \(error)")
        }
    }
    
    private func checkProximityAndVibrate(objects: [DetectedObject], depthData: AVDepthData) {
        let depthMap = depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32).depthDataMap
        
        for object in objects {
            let box = object.boundingBox
            let centerX = Int(box.midX * CGFloat(CVPixelBufferGetWidth(depthMap)))
            let centerY = Int(box.midY * CGFloat(CVPixelBufferGetHeight(depthMap)))
            
            guard centerX >= 0 && centerX < CVPixelBufferGetWidth(depthMap) &&
                  centerY >= 0 && centerY < CVPixelBufferGetHeight(depthMap) else {
                continue
            }
            
            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
            let baseAddress = CVPixelBufferGetBaseAddress(depthMap)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
            
            let address = baseAddress! + centerY * bytesPerRow + centerX * MemoryLayout<Float32>.size
            let distance = address.assumingMemoryBound(to: Float32.self).pointee
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            
            if distance < 1.0 {
                DispatchQueue.main.async {
                    self.impactFeedback.impactOccurred(intensity: 1.0)
                    
                    if !self.isCurrentlySpeaking {
                        let utterance = AVSpeechUtterance(string: "Close object ahead")
                        utterance.rate = 0.7
                        utterance.volume = 1.0
                        self.synthesizer.speak(utterance)
                    }
                }
            }
        }
    }
}

extension ObjectDetector: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isCurrentlySpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isCurrentlySpeaking = false
    }
} 