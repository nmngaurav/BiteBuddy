import SwiftUI

/// Premium voice input sheet with animated recording and edit/confirm flow
struct VoiceInputSheet: View {
    @Binding var isPresented: Bool
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var recordingState: RecordingState = .idle
    @State private var transcribedText: String = ""
    @FocusState private var isEditingText: Bool
    
    var onConfirm: (String) -> Void
    
    enum RecordingState {
        case idle
        case recording
        case transcribed
        case editing
    }
    
    var body: some View {
        ZStack {
            // Premium Glass Background
            Theme.Colors.backgroundPrimary.ignoresSafeArea()
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack {
                // 1. Dynamic Header (Close Button)
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(12)
                            .background(Circle().fill(.regularMaterial))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // 2. Dynamic Text Area (The "Live Feed")
                // Starts focused in center, moves up as content grows
                VStack(alignment: .leading, spacing: 10) {
                    if transcribedText.isEmpty && !speechRecognizer.isRecording {
                        Text("Tap mic to start...")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.Colors.textTertiary)
                            .transition(.opacity)
                    } else if transcribedText.isEmpty && speechRecognizer.isRecording {
                        Text("Listening...")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.Colors.textTertiary.opacity(0.7))
                            .transition(.opacity)
                    }
                    
                    if !transcribedText.isEmpty {
                        ScrollView {
                            Text(transcribedText)
                                .font(.system(size: 32, weight: .medium, design: .rounded)) // Larger, premium font
                                .foregroundColor(Theme.Colors.textPrimary)
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .transition(.opacity)
                        }
                        .frame(maxHeight: 400) // Allow growing up to 400pt
                    }
                }
                .padding(.horizontal, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: transcribedText)
                
                Spacer()
                
                // 3. Bottom Controls & Visualizer
                VStack(spacing: 40) {
                    // Fluid Visualizer
                    if recordingState == .recording {
                        FluidAudioVisualizer(isRecording: true)
                            .frame(height: 60)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Control Buttons
                    ZStack {
                        if recordingState == .recording {
                            // STOP BUTTON
                            Button(action: toggleRecording) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .red.opacity(0.5), radius: 20, x: 0, y: 10)
                                    
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .transition(.scale)
                        } else {
                            // EDIT / CONFIRM BUTTONS
                            HStack(spacing: 25) {
                                // Re-record / Edit
                                Button(action: {
                                    startRecording()
                                }) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                        .frame(width: 60, height: 60)
                                        .background(Circle().fill(.regularMaterial))
                                }
                                
                                // Confirm (Primary Action)
                                Button(action: handleConfirm) {
                                    HStack {
                                        Text("Send")
                                        Image(systemName: "paperplane.fill")
                                    }
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(
                                        LinearGradient(
                                            colors: [Theme.Colors.primary, Theme.Colors.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 15, y: 5)
                                }
                                .disabled(transcribedText.isEmpty)
                                .opacity(transcribedText.isEmpty ? 0.5 : 1.0)
                            }
                            .padding(.horizontal, 30)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }

        .onAppear {
            // Auto-start recording
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                startRecording()
            }
        }
        .onChange(of: speechRecognizer.transcribedText) { oldValue, newValue in
            if !newValue.isEmpty {
                transcribedText = newValue
            }
        }
        .onChange(of: speechRecognizer.isRecording) { _, isRecording in
            if !isRecording && recordingState == .recording && !transcribedText.isEmpty {
                // Transition to transcribed state
                withAnimation {
                    recordingState = .transcribed
                }
            }
        }
    }
    
    private func startRecording() {
        recordingState = .recording
        transcribedText = ""
        speechRecognizer.startRecording()
        BiteEffects.impactVibe(style: .medium)
    }
    
    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
            BiteEffects.impactVibe(style: .light)
        } else {
            startRecording()
        }
    }
    
    private func handleConfirm() {
        guard !transcribedText.isEmpty else { return }
        BiteEffects.selectionVibe()
        onConfirm(transcribedText)
        isPresented = false
    }
}

/// Animated recording view with waveform
struct RecordingView: View {
    let isRecording: Bool
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated Waveform
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midY = height / 2
                
                for i in 0..<5 {
                    let offset = CGFloat(i) * 15
                    let amplitude: CGFloat = isRecording ? 30 : 5
                    let frequency: CGFloat = 0.02
                    
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: midY))
                    
                    for x in stride(from: 0, through: width, by: 2) {
                        let y = midY + sin((x + offset + animationPhase) * frequency) * amplitude
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    context.stroke(
                        path,
                        with: .color(Theme.Colors.primary.opacity(0.3 + CGFloat(i) * 0.15)),
                        lineWidth: 2
                    )
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 40)
            
            // Recording Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .opacity(isRecording ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
                
                Text("Speak now...")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = 360
            }
        }
    }
}
