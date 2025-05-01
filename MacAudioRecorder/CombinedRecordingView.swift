import SwiftUI
import AVFoundation
#if os(macOS)
import AppKit
#endif

#if os(macOS)
/// NSVisualEffectView wrapper for blur / vibrancy backgrounds (macOS 11+)
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
#endif

@available(macOS 11.0, *)
struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                VisualEffectBlur(material: .sidebar) // choose material that provides blur on most macOS versions
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            )
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    func glassEffect() -> some View {
        modifier(GlassBackground())
    }
}

@available(macOS 11.0, *)
struct CombinedRecordingView: View {
    // Environment variable to control the view's presentation state (for dismissing the sheet)
    @Environment(\.presentationMode) var presentationMode

    // StateObject for the combined audio engine
    @StateObject private var combinedEngine = CombinedAudioEngine()
    // Transcriber + View-Model
    @StateObject private var transcriber: WhisperTranscriber
    @StateObject private var viewModel: TranscriptionViewModel

    // Playback state
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false

    init() {
        let t = WhisperTranscriber()
        _transcriber = StateObject(wrappedValue: t)
        _viewModel = StateObject(wrappedValue: TranscriptionViewModel(transcriber: t, localLLMService: LocalLLMService.shared))
    }

    var body: some View {
        // Background gradient + glass container
        ZStack {
            // Underlying gradient to visualize blur
            LinearGradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            // Main glass container
            VStack(spacing: 20) {
                // Logo
                Image("nk_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                Text("NeuroKick")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .padding(.top, 40)

                // Live transcript
                ScrollView {
                    Text(viewModel.transcript.isEmpty ? "(Listening...)" : viewModel.transcript)
                        .textSelection(.enabled) // Enable text selection
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .foregroundColor(.black)
                }
                .frame(height: 320)
                .glassEffect()

                HStack(spacing: 20) {
                    // Record / Stop Button
                    Button {
                        if combinedEngine.isRecording {
                            combinedEngine.stopRecording()
                        } else {
                            combinedEngine.startRecording()
                        }
                    } label: {
                        Label(combinedEngine.isRecording ? "Stop Recording" : "Record Mic + System",
                              systemImage: combinedEngine.isRecording ? "stop.circle.fill" : "record.circle.fill")
                            .frame(minWidth: 120)
                    }
                    .applyButtonStyling(color: .red)

                    // Play / Pause Button
                    // Button {
                    //     togglePlayback()
                    // } label: {
                    //     Label(isPlaying ? "Pause" : "Play",
                    //           systemImage: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    //         .frame(minWidth: 120)
                    // }
                    // .applyButtonStyling(color: .blue)
                    // .disabled(combinedEngine.isRecording || combinedEngine.completedRecordingURL == nil)

                    // Save Transcript Button
                    Button {
                        saveTranscript()
                    } label: {
                        Label("Save Transcript", systemImage: "doc.text.fill")
                            .frame(minWidth: 120)
                    }
                    .applyButtonStyling(color: .orange)
                    .disabled(viewModel.transcript.isEmpty)
                }

                // DeepSeek analysis controls
                HStack {
                    Button("Workplace Analysis") {
                        viewModel.analyze()
                    }
                    .applyButtonStyling(color: .blue)
                    .disabled(viewModel.isAnalyzing || viewModel.transcript.isEmpty)

                    Button("General Summary") {
                        viewModel.summarize()
                    }
                    .applyButtonStyling(color: .purple)
                    .disabled(viewModel.isAnalyzing || viewModel.transcript.isEmpty)

                    Button("Behavioural Analysis") {
                        viewModel.behavioralAnalyze()
                    }
                    .applyButtonStyling(color: .green)
                    .disabled(viewModel.isAnalyzing || viewModel.transcript.isEmpty)

                    if viewModel.isAnalyzing {
                        ProgressView()
                    }
                }

                // Summary output
                if !viewModel.summary.isEmpty {
                    VStack(spacing: 8) {
                        ScrollView {
                            Text(viewModel.summary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .foregroundColor(.black)
                        }
                        .frame(height: 150)
                        .glassEffect()

                        Button {
                            saveSummary()
                        } label: {
                            Label("Save Summary", systemImage: "square.and.arrow.down")
                                .frame(minWidth: 120)
                        }
                        .applyButtonStyling(color: .green)
                    }
                }

                Spacer()

                // Back button to dismiss the sheet
                // Button("Back") {
                //     presentationMode.wrappedValue.dismiss()
                // }
                // .padding(.bottom, 20)
                // .applyButtonStyling(color: .gray)
            }
            .padding(.top, -200)
            .padding(.horizontal, 30)
            .glassEffect()
            .frame(width: 550, height: 400)
            .foregroundColor(.white)
        }
        .onAppear {
            combinedEngine.transcriber = transcriber
        }
    }

    // MARK: - Playback
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            combinedEngine.statusMessage = "Playback stopped."
            return
        }

        guard let url = combinedEngine.completedRecordingURL else {
            combinedEngine.statusMessage = "No recording to play."
            return
        }

        do {
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0
            print("[Playback] Attempting to play file at \(url.path) size: \(fileSize) bytes")

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1.0 // ensure audible
            audioPlayer?.prepareToPlay()
            if audioPlayer?.play() == true {
                print("[Playback] AVAudioPlayer started successfully. duration: \(audioPlayer?.duration ?? 0)s")
                isPlaying = true
                combinedEngine.statusMessage = "Playing..."

                // Automatically reset state when finished
                DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
                    isPlaying = false
                    combinedEngine.statusMessage = "Playback finished."
                }
            } else {
                print("[Playback] AVAudioPlayer failed to start.")
                // Convert to M4A for playback
                exportM4A(from: url, to: url.deletingPathExtension().appendingPathExtension("m4a"))
                combinedEngine.statusMessage = "Failed to play, converting to M4A..."
            }
        } catch {
            combinedEngine.statusMessage = "Playback error: \(error.localizedDescription)"
        }
    }

    // MARK: - Save Recording
    private func saveRecording() {
        guard let sourceURL = combinedEngine.completedRecordingURL else {
            combinedEngine.statusMessage = "Error: No recording available to save."
            return
        }

        let panel = NSSavePanel()
        panel.title = "Save NeuroKick"
        panel.nameFieldStringValue = "NeuroKick.m4a"
        panel.allowedFileTypes = ["m4a"]
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let destURL = panel.url {
                exportM4A(from: sourceURL, to: destURL)
            } else {
                combinedEngine.statusMessage = "Save cancelled."
            }
        }
    }

    // MARK: - Save Transcript
    private func saveTranscript() {
        let panel = NSSavePanel()
        panel.title = "Save Transcript"
        panel.nameFieldStringValue = "Transcript.txt"
        panel.allowedFileTypes = ["txt"]
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let destURL = panel.url {
                do {
                    try viewModel.transcript.write(to: destURL, atomically: true, encoding: .utf8)
                    combinedEngine.statusMessage = "Transcript saved to \(destURL.lastPathComponent)"
                } catch {
                    combinedEngine.statusMessage = "Failed to save transcript: \(error.localizedDescription)"
                }
            } else {
                combinedEngine.statusMessage = "Save transcript cancelled."
            }
        }
    }

    // MARK: - Save Summary
    private func saveSummary() {
        guard !viewModel.summary.isEmpty else { return }

        let panel = NSSavePanel()
        panel.title = "Save Summary"
        panel.nameFieldStringValue = "Summary.txt"
        panel.allowedFileTypes = ["txt"]
        panel.canCreateDirectories = true

        panel.begin { response in
            if response == .OK, let destURL = panel.url {
                do {
                    try viewModel.summary.write(to: destURL, atomically: true, encoding: .utf8)
                    combinedEngine.statusMessage = "Summary saved to \(destURL.lastPathComponent)"
                } catch {
                    combinedEngine.statusMessage = "Failed to save summary: \(error.localizedDescription)"
                }
            } else {
                combinedEngine.statusMessage = "Save summary cancelled."
            }
        }
    }

    // Convert CAF/PCM to M4A using AVAssetExportSession
    private func exportM4A(from sourceURL: URL, to destURL: URL) {
        let asset = AVAsset(url: sourceURL)

        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            combinedEngine.statusMessage = "M4A export not supported."
            return
        }

        exporter.outputURL = destURL
        exporter.outputFileType = .m4a

        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                switch exporter.status {
                case .completed:
                    self.combinedEngine.statusMessage = "Saved M4A to \(destURL.lastPathComponent)"
                case .failed, .cancelled:
                    self.combinedEngine.statusMessage = "Export failed: \(exporter.error?.localizedDescription ?? "Unknown error")"
                default:
                    break
                }
            }
        }
    }
}

@available(macOS 11.0, *)
struct CombinedRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        CombinedRecordingView()
    }
}
