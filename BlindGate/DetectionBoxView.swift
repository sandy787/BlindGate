import SwiftUI

struct DetectionBox: Identifiable {
    let id = UUID()
    let rect: CGRect
    let label: String
    let confidence: Float
}

struct DetectionBoxView: View {
    let detectionBoxes: [DetectionBox]
    let previewSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(detectionBoxes) { box in
                    let scaledRect = CGRect(
                        x: box.rect.minX * geometry.size.width,
                        y: box.rect.minY * geometry.size.height,
                        width: box.rect.width * geometry.size.width,
                        height: box.rect.height * geometry.size.height
                    )
                    
                    Rectangle()
                        .path(in: scaledRect)
                        .stroke(Color.green, lineWidth: 2)
                    
                    Text("\(box.label) (\(Int(box.confidence * 100))%)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .position(
                            x: scaledRect.minX,
                            y: scaledRect.minY - 10
                        )
                }
            }
        }
    }
} 