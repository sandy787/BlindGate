//
//  ContentView.swift
//  BlindGate
//
//  Created by prajwal sanap on 05/12/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            if cameraManager.isSetup {
                ZStack {
                    CameraPreview()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    DetectionBoxView(
                        detectionBoxes: cameraManager.detectionBoxes,
                        previewSize: UIScreen.main.bounds.size
                    )
                    
                    VStack {
                        Spacer()
                        Text(cameraManager.current_text)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                    }
                }
            } else {
                ProgressView("Setting up camera...")
            }
        }
        .ignoresSafeArea()
        .environmentObject(cameraManager)
    }
}

struct CameraPreview: UIViewRepresentable {
    @EnvironmentObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let captureSession = cameraManager.captureSession else {
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

#Preview {
    ContentView()
}
