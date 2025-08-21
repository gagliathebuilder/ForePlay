# ⛳️ ForePlay - Golf Swing Analysis App

**ForePlay** is a premium iOS golf swing analysis app that combines computer vision, AI coaching, and professional-grade UI to help golfers improve their game through real-time feedback and personalized instruction.

## 🎯 Features

### **Golf-Themed UI Components**
- **GolfMicButton**: Golf ball-styled microphone with dimples and press animations
- **TeeRecordButton**: Tee-shaped record button with pulsing animation
- **OverlayEditor**: Draggable target line and swing plane guides with persistence
- **MetricsChip**: Compact display for swing analysis results
- **VoiceStateChip**: CaDi voice state with animated equalizer bars

### **AI Swing Analysis**
- **Vision-based pose detection** on recorded clips (24 frames)
- **Three key metrics**:
  - **Tempo**: Backswing vs downswing ratio (target 2.5:1 to 3.5:1)
  - **Plane**: Shaft angle at top (target 45°-60°)
  - **Sway**: Hip movement delta (target ±8cm)
- **Smart coaching feedback** based on actual metrics
- **All processing on-device** (except OpenAI voice)

### **Voice Agent (CaDi)**
- **Automatic fallback**: OpenAI TTS if API key exists, otherwise enhanced local voice
- **Metrics-based coaching**: Personalized feedback using analysis results
- **Push-to-talk**: Hold golf ball mic to activate, release for coaching
- **Future-ready**: Stubbed methods for AirPods/always-listening

### **Professional UX**
- **PGA color scheme**: Green/white with gold accents
- **Smooth animations**: Button bounce, fade transitions, pulsing effects
- **Accessibility**: Proper labels, hints, dynamic type support
- **Responsive layout**: Safe areas, small/large iPhone support

## 🏗️ Architecture

### **Core Components**
- **`VoiceEngine.swift`**: OpenAI TTS with automatic fallback to local enhanced voices
- **`AnalysisKit.swift`**: Vision-based swing analysis with metrics calculation
- **`CaptureView.swift`**: Redesigned with golf-themed controls and overlay editing
- **`OverlayEditor.swift`**: Draggable guides with AppStorage persistence
- **`GolfMicButton.swift`**: Golf ball-styled microphone with haptic feedback
- **`TeeRecordButton.swift`**: Tee-shaped record button with animations

### **Data Flow**
```
Camera → Vision Analysis → Metrics → CaDi Coaching → Voice Feedback
   ↓
Recording → AnalysisKit → AnalysisResult → UI Display
```

### **Dependencies**
- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Camera capture, video playback, audio
- **Vision**: Human pose detection and analysis
- **CoreMedia**: Video processing and time management
- **OpenAI Audio API**: Optional enhanced TTS voices

## 🚀 Setup & Installation

### **Prerequisites**
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### **1. Clone Repository**
```bash
git clone https://github.com/gagliathebuilder/ForePlay.git
cd ForePlay
```

### **2. Open in Xcode**
```bash
open ForePlay.xcodeproj
```

### **3. Configure Info.plist**
Add these required permissions to your `Info.plist`:

```xml
<!-- Required -->
<key>NSCameraUsageDescription</key>
<string>ForePlay needs camera access to record your golf swings for analysis and coaching feedback.</string>

<key>NSMicrophoneUsageDescription</key>
<string>ForePlay needs microphone access so you can talk to CaDi, your voice golf coach.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>ForePlay uses speech recognition to understand your questions and provide personalized golf coaching from CaDi.</string>

<!-- Optional: For OpenAI voices -->
<key>OPENAI_API_KEY</key>
<string>your-openai-api-key-here</string>
```

### **4. Build & Run**
- Select your target device/simulator
- Press `Cmd + R` to build and run

## 🔧 Configuration

### **OpenAI Voice Integration**
To enable enhanced TTS voices:

1. Get an API key from [OpenAI](https://platform.openai.com/api-keys)
2. Add `OPENAI_API_KEY` to your `Info.plist`
3. The app will automatically use OpenAI voices when available

**Supported Models**: `gpt-4o-mini-tts`, `tts-1`
**Supported Voices**: `alloy`, `ash`, `echo`, `fable`, `onyx`, `nova`, `shimmer`

### **Customization**
- **Colors**: Modify `Color` extensions in component files
- **Animations**: Adjust timing and easing in button components
- **Overlays**: Customize guide positions and styles in `OverlayEditor`

## 📱 Usage

### **Recording a Swing**
1. Open the **Record** tab
2. Position yourself in frame with golf club
3. Tap the **TeeRecordButton** to start recording
4. Execute your golf swing
5. Tap again to stop recording

### **Analysis & Feedback**
1. After recording, analysis runs automatically
2. View metrics in the **MetricsChip** above controls
3. Hold the **GolfMicButton** to get coaching from CaDi
4. Use **OverlayEditor** to set target line and swing plane

### **Comparing Swings**
1. Go to **Library** tab
2. Select two swings to compare
3. Use **ComparisonView** for side-by-side analysis
4. Sync scrubber to analyze specific positions

## 🧪 Testing

### **Unit Tests**
```bash
# Run tests in Xcode
Cmd + U
```

### **UI Tests**
- Test overlay dragging and persistence
- Verify haptic feedback on button presses
- Check accessibility labels and hints

### **Integration Tests**
- Test camera permissions and recording
- Verify analysis pipeline end-to-end
- Test voice fallback when OpenAI unavailable

## 🔒 Privacy & Security

### **Data Handling**
- **All videos stay local** on device
- **No cloud storage** by default
- **No analytics** or tracking
- **Vision processing** happens on-device

### **Permissions**
- **Camera**: Required for swing recording
- **Microphone**: Required for voice coaching
- **Speech Recognition**: Required for CaDi interaction

### **OpenAI Integration**
- **Voice data** processed through OpenAI TTS API
- **No persistent storage** on OpenAI servers
- **Automatic fallback** to local voice if API unavailable

## 🚧 Future Enhancements

### **Planned Features**
- **Realtime API**: Interactive voice conversations with GPT-4o
- **Advanced overlays**: Angle tools, club path visualization
- **Export features**: Burn-in overlays, captions, sharing
- **AirPods integration**: Always-listening mode for hands-free coaching

### **Performance Optimizations**
- **Metal acceleration** for video processing
- **Background analysis** for longer clips
- **Caching** for repeated analysis

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### **Development Guidelines**
- Follow Swift style guidelines
- Add unit tests for new functionality
- Update documentation for API changes
- Test on multiple device sizes

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple Vision Framework** for pose detection
- **OpenAI** for enhanced TTS capabilities
- **SwiftUI** for modern iOS development
- **Golf community** for feedback and testing

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/gagliathebuilder/ForePlay/issues)
- **Discussions**: [GitHub Discussions](https://github.com/gagliathebuilder/ForePlay/discussions)
- **Email**: [your-email@domain.com]

---

**Built with ❤️ for the golf community**

*ForePlay - Elevate Your Game*
