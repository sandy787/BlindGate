# BlindGate - An iOS App for Object Recognition and Accessibility

BlindGate is an iOS application designed to assist blind and visually impaired individuals by identifying objects in their surroundings and providing voice-based feedback. This app leverages YOLOv5 for real-time object detection and accessibility features to enhance independence and situational awareness.

---

## Features
- **Object Recognition**: Uses the device camera and YOLOv5 to detect and identify objects in real-time.
- **Voice Feedback**: Provides auditory descriptions of identified objects using text-to-speech.
- **Accessibility**: Fully compatible with VoiceOver and provides haptic feedback for better interaction.
- **User-Friendly Interface**: Minimalistic design with gesture-based controls for easy navigation.

---
### Home Screen
<img src="screenshots/s1.png" alt="Home Screen" width="400"/>

### Object Detection in Action
<img src="screenshots/s2.png" alt="Object Detection" width="400"/>

-------------
## Technology Stack
- **Language**: Swift
- **Frameworks and Tools**:
  - **YOLOv5**: For object detection using a pre-trained model exported to CoreML.
  - **Vision Framework**: To integrate YOLOv5 for on-device inference.
  - **AVFoundation**: For text-to-speech feedback.
  - **SwiftUI**: For creating an accessible and intuitive user interface.

---

## How It Works
1. **Object Detection**:
   - YOLOv5 is used for real-time object recognition.
   - The YOLOv5 PyTorch model is converted to CoreML format to run natively on iOS devices.
   
2. **Voice Feedback**:
   - Identified objects are described to the user through iOS's text-to-speech functionality.

3. **Accessibility**:
   - Full VoiceOver support is provided for visually impaired users.
   - Haptic feedback is used to notify users of successful detections or errors.

---

## Getting Started
### Prerequisites
- macOS with Xcode installed.
- An iOS device with a camera (the app requires camera access).
- YOLOv5 CoreML model file (`.mlmodel`).

### Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/VisionAid.git
