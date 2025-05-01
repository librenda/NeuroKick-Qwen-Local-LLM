import Foundation
import AVFoundation
import ScreenCaptureKit
import Combine // For @Published properties later

// Class responsible for handling simultaneous Mic + System Audio recording
@available(macOS 12.3, *) // ScreenCaptureKit requires macOS 12.3+
class CombinedAudioEngine: NSObject, ObservableObject, SCStreamDelegate, SCStreamOutput {
    
    // MARK: - Properties
    
    // --- Audio Engine --- 
    private let engine = AVAudioEngine()
    private let mixer: AVAudioMixerNode // Main mixer - accessible via engine.mainMixerNode
    private let recordingMixer = AVAudioMixerNode() // Collect combined audio to write
    private let micMixer = AVAudioMixerNode()       // Per-source gain stage for mic
    private let systemMixer = AVAudioMixerNode()    // Per-source gain stage for system audio
    private let monitorMixer = AVAudioMixerNode()   // Swallows audio to avoid monitoring
    private let systemAudioPlayerNode = AVAudioPlayerNode() // Node to feed system audio into
    
    // --- Screen Capture (System Audio) --- 
    private var stream: SCStream?
    private var availableContent: SCShareableContent? // Available displays/windows
    private var filter: SCContentFilter? // Filter for selecting content
    private let serialQueue = DispatchQueue(label: "com.example.MacAudioRecorder.ScreenCaptureQueue") // Dedicated queue for capture callbacks
    
    // --- File Writing ---
    private var outputFile: AVAudioFile?
    private var outputFileURL: URL? // URL for the temporary recording file
    private let outputBus = 0 // Bus 0 is standard output
    
    // --- State --- 
    @Published var isRecording: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var completedRecordingURL: URL? = nil // URL of the last completed recording
    // TODO: Add more specific state vars if needed (isRecordingMic, isRecordingSystem)
    
    // --- Transcription ---
    weak var transcriber: WhisperTranscriber?
    
    // MARK: - Initialization
    
    override init() {
        self.mixer = engine.mainMixerNode // Get mixer reference
        super.init() // Ensure superclass is initialized (Required for NSObject subclassing)
        setupAudioEngine()
        // Start fetching shareable content immediately
        updateShareableContent()
        print("CombinedAudioEngine Initialized and basic setup done.")
    }
    
    // MARK: - Public Methods (Recording Control)
    
    func startRecording() {
        print("[Engine] startRecording() called.")
        // Reset completed URL from previous recording
        completedRecordingURL = nil
        
        // TODO: Permissions checks (Mic, Screen Recording)
        // Mic permission check should happen here first
        // Screen Recording permission check should happen here
 
        // TODO: Re-attach nodes if stopped previously
        // Start screen capture stream
        Task(priority: .userInitiated) {
            await startScreenCapture()
        }
         
        // Attach the dedicated recording mixer
        engine.attach(recordingMixer)

        // --- Make engine connections ---
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Attach pre-mixers
        engine.attach(micMixer)
        engine.attach(systemMixer)

        // Mic chain
        engine.connect(inputNode, to: micMixer, format: inputFormat)
        engine.connect(micMixer, to: recordingMixer, format: inputFormat)
        print("Connected Mic -> micMixer -> recordingMixer")

        // System chain
        // Defer format selection for system audio; use nil so it adapts to first buffer
        engine.connect(systemAudioPlayerNode, to: systemMixer, format: nil)
        engine.connect(systemMixer, to: recordingMixer, format: nil)
        print("Connected SystemAudioPlayer -> systemMixer -> recordingMixer")

        // Connect recordingMixer to monitorMixer (volume 0) to swallow audio
        engine.attach(monitorMixer)
        let mainFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(recordingMixer, to: monitorMixer, format: mainFormat)
        engine.connect(monitorMixer, to: engine.mainMixerNode, format: mainFormat)
        monitorMixer.outputVolume = 0.0
        print("Connected recordingMixer -> monitorMixer (muted) -> mainMixer to keep graph valid without monitoring.")

        do {
            try engine.start()
            // Delay auto-gain balance until formats propagate and nodes produce audio
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.autoBalanceLevels()
            }
            try setupFileWritingTap(on: recordingMixer)
            print("AVAudioEngine started successfully and file writing tap installed.")
            // TODO: Update state properly after all setup
            isRecording = true // Placeholder
            statusMessage = "Recording Combined..." // Placeholder
            transcriber?.start()
        } catch {
            print("Error starting AVAudioEngine or setting up tap: \(error.localizedDescription)")
            statusMessage = "Error starting engine/tap: \(error.localizedDescription)"
            // Perform cleanup if start fails
            stopRecording()
        }
    }
    
    func stopRecording() {
        print("[Engine] stopRecording() called.")
        isRecording = false // Update state immediately
        statusMessage = "Stopping Combined..."
        engine.stop()
        // Stop screen capture stream
        if let stream = stream {
            stream.stopCapture()
            print("SCStream stopped.")
            self.stream = nil
        }
        print("AVAudioEngine stopped.")
        
        // Remove tap and close file
        recordingMixer.removeTap(onBus: outputBus)
        let finishedURL = outputFileURL // Capture URL before nil'ing outputFile
        outputFile = nil // Releases the file handle
        print("Removed mixer tap and closed output file. File available at: \(finishedURL?.path ?? "Not found")")
 
        // Convert to M4A for easy playback/sharing
        if let cafURL = finishedURL {
            convertToM4A(cafURL: cafURL) { m4aURL in
                DispatchQueue.main.async {
                    if let m4aURL = m4aURL {
                        self.completedRecordingURL = m4aURL
                        self.statusMessage = "Recording finished. Ready to play/save."
                    } else {
                        // Fallback to CAF if conversion failed
                        self.completedRecordingURL = cafURL
                        self.statusMessage = "Recording finished (CAF). Conversion failed."
                    }
                }
            }
        }
 
        engine.reset()
        print("AVAudioEngine reset.")
        // TODO: Update state
        // statusMessage = "Stopping Combined..." // Placeholder
        
        // TODO: Trigger save panel? Or return file URL?
        outputFile = nil
        transcriber?.stop()
    }
    
    // MARK: - Private Setup Helpers (TBD)
    
    private func setupAudioEngine() {
        // Attach nodes that will be used
        let inputNode = engine.inputNode // Ensure input node is available early
        engine.attach(systemAudioPlayerNode)
        
        // Initial connections (more connections might happen in startRecording)
        // We will connect mic and system audio source to the mixer later.
        
        // Prepare the engine but don't start it here
        engine.prepare()
        print("AVAudioEngine prepared.")
    }
    
    // MARK: - Screen Capture Setup & Control
    
    private func updateShareableContent() {
        SCShareableContent.getExcludingDesktopWindows(true, onScreenWindowsOnly: true) { content, error in
            if let error = error {
                print("Error getting shareable content: \(error.localizedDescription)")
                // TODO: Update status message for UI
                self.statusMessage = "Error getting screen content: \(error.localizedDescription)"
                return
            }
            self.availableContent = content
            print("Shareable content updated.")
            // Optionally update UI if needed (e.g., to allow user selection)
        }
    }
    
    private func setupScreenCapture() {
        guard let availableContent = availableContent else {
            print("Error: Shareable content not available.")
            statusMessage = "Error: Screen content not found."
            return
        }
        
        // Configuration: Find the first display, or potentially an application window
        // For system audio, capturing a display is typical.
        guard let display = availableContent.displays.first else {
             print("Error: No display found for capture.")
             statusMessage = "Error: No display found."
             return
        }
        
        // Create a content filter to capture the chosen display (and exclude our app)
        // For system-wide audio, we typically capture a display.
        // Exclude the current app's windows to avoid potential feedback loops if playing audio.
        let excludedApps = availableContent.applications.filter { app in
            Bundle.main.bundleIdentifier == app.bundleIdentifier
        }
        self.filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
        
        // Create the stream configuration
        let config = SCStreamConfiguration()
        config.width = 2 // Minimal width for audio-only
        config.height = 2 // Minimal height for audio-only
        config.minimumFrameInterval = CMTime(value: 1, timescale: 60) // Low frame rate
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = true // Avoid capturing audio generated by this app
        config.sampleRate = Int(engine.outputNode.outputFormat(forBus: 0).sampleRate) // Match engine's sample rate
        
        do {
            stream = SCStream(filter: filter!, configuration: config, delegate: self)
            // Add stream output for audio
            try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: serialQueue)
            print("SCStream initialized and output added.")
        } catch {
            print("Error initializing SCStream or adding output: \(error.localizedDescription)")
            statusMessage = "Error setting up screen capture: \(error.localizedDescription)"
        }
    }
    
    private func startScreenCapture() async {
        setupScreenCapture() // Ensure stream is configured
        
        guard let stream = stream else {
            print("SCStream not initialized, cannot start capture.")
            statusMessage = "Error: Screen capture not ready."
            return
        }
        
        do {
            try await stream.startCapture()
            print("SCStream capture started.")
        } catch {
            print("Error starting SCStream capture: \(error.localizedDescription)")
            // TODO: Handle error - update UI state, stop engine etc.
            statusMessage = "Error starting screen capture: \(error.localizedDescription)"
            stopRecording() // Stop everything if screen capture fails to start
        }
    }
    
    private func setupFileWritingTap(on tapNode: AVAudioNode) throws {
        // --- Define Output Format --- 
        // Use a common format like linear PCM which is widely compatible within CAF
        // Or potentially AAC for compressed M4A (would require different AVAudioFile settings)
        // Let's stick with the mixer's output format initially for simplicity inside CAF.
        let format = tapNode.outputFormat(forBus: outputBus)
 
         // Create a unique temporary file URL
         let tempDir = FileManager.default.temporaryDirectory
         outputFileURL = tempDir.appendingPathComponent("combined_recording_").appendingPathExtension("caf") // caf supports many formats
        
        print("Setting up file writing tap. Output URL: \(outputFileURL!.path)")
        
        // Remove existing file if it exists (e.g., from a previous failed recording)
        if let url = outputFileURL, FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Create the AVAudioFile
        outputFile = try AVAudioFile(forWriting: outputFileURL!, settings: format.settings)
        
        // Install the tap
        tapNode.installTap(onBus: outputBus, bufferSize: 4096, format: format) { [weak self] (buffer, time) in
            guard let self = self, let outputFile = self.outputFile else { return }
            
            do {
                // Write the buffer to the file
                try outputFile.write(from: buffer)
                self.transcriber?.append(buffer: buffer)
            } catch {
                print("Error writing audio buffer to file: \(error.localizedDescription)")
                // Consider stopping recording or setting an error state here
                self.statusMessage = "Error writing file: \(error.localizedDescription)"
                // Maybe call self.stopRecording() ? Depends on desired behavior
            }
        }
    }

    private func checkPermissions() {
        // ... mic and screen recording checks ...
    }
    
    // Required SCStreamDelegate method for handling stream errors/stop events
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("System audio stream stopped with error: \(error.localizedDescription)")
        // We should probably stop the recording if the system audio stream fails
        DispatchQueue.main.async {
            self.statusMessage = "System audio error: \(error.localizedDescription)"
            // Check if we are still recording, might have been stopped already
            if self.isRecording {
                self.stopRecording() 
            }
        }
    }
}

// MARK: - SCStreamOutput Delegate (for System Audio)

extension CombinedAudioEngine {
    // Separate conformance for clarity
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Since project target is now macOS 13.0+, we can directly check for .audio
        guard type == .audio else { return }
        
        // Ensure the engine is running and we're expecting audio
        guard engine.isRunning else { return }
        
        // Convert CMSampleBuffer to AVAudioPCMBuffer
        // Get the format description from the CMSampleBuffer
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee else {
            print("Error getting audio format description from sample buffer")
            return
        }
        
        // Create an AVAudioFormat instance from the stream description
        // Explicitly cast channel count to AVAudioChannelCount (UInt32)
        guard let inputFormat = AVAudioFormat(standardFormatWithSampleRate: streamBasicDescription.mSampleRate,
                                              channels: AVAudioChannelCount(streamBasicDescription.mChannelsPerFrame)) else {
             print("Error creating AVAudioFormat from stream description")
             return
        }
        
        // Calculate frame length
        // Ensure frameLength is explicitly AVAudioFrameCount (UInt32)
        let frameLength = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        
        // Create an AVAudioPCMBuffer
        // Ensure frameCapacity is AVAudioFrameCount (UInt32)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(frameLength)) else {
            print("Error creating AVAudioPCMBuffer")
            return
        }
        pcmBuffer.frameLength = frameLength
        
        // Copy the audio data from CMSampleBuffer to AVAudioPCMBuffer
        CMSampleBufferCopyPCMDataIntoAudioBufferList(sampleBuffer,
                                                     at: 0,
                                                     frameCount: Int32(frameLength), // Explicit cast
                                                     into: pcmBuffer.mutableAudioBufferList)
        
        // Ensure player's outputFormat matches buffer's channel count
        if systemAudioPlayerNode.outputFormat(forBus: 0).channelCount == 0 {
            // not yet set: connect formats by reconnecting
            engine.disconnectNodeOutput(systemAudioPlayerNode)
            engine.connect(systemAudioPlayerNode, to: systemMixer, format: pcmBuffer.format)
        }
        
        // Schedule the buffer on the player node
        systemAudioPlayerNode.scheduleBuffer(pcmBuffer) {
            // Optional completion handler
            // print("System audio buffer scheduled") // DEBUG - Can be noisy
        }
        
        // Ensure the player node is playing to process scheduled buffers
        if !systemAudioPlayerNode.isPlaying {
            systemAudioPlayerNode.play()
            print("Started System Audio Player Node.")
        }
    }
}

// MARK: - Post-processing

extension CombinedAudioEngine {
    /// Convert the raw CAF to M4A (AAC) for playback. Calls completion on a background queue.
    private func convertToM4A(cafURL: URL, completion: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: cafURL)

        // Ensure asset tracks are loaded before creating exporter
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "tracks", error: &error)

            guard status == .loaded else {
                print("[Export] Asset tracks not loaded: \(error?.localizedDescription ?? "unknown")")
                completion(nil)
                return
            }

            guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                print("[Export] Unable to create exporter for M4A.")
                completion(nil)
                return
            }

            let m4aURL = cafURL.deletingPathExtension().appendingPathExtension("m4a")

            // Remove existing file if present
            try? FileManager.default.removeItem(at: m4aURL)

            exporter.outputURL = m4aURL
            exporter.outputFileType = .m4a

            exporter.exportAsynchronously {
                if exporter.status == .completed {
                    print("[Export] M4A created at \(m4aURL.path)")
                    completion(m4aURL)
                } else {
                    print("[Export] Failed: \(exporter.error?.localizedDescription ?? "unknown") | status: \(exporter.status.rawValue)")
                    completion(nil)
                }
            }
        }
    }
}

// MARK: - Auto-balance

extension CombinedAudioEngine {
    private func autoBalanceLevels() {
        measureRMS(on: micMixer, duration: 1.0) { [weak self] micRMS in
            guard let self = self else { return }
            self.measureRMS(on: self.systemMixer, duration: 1.0) { sysRMS in
                guard micRMS > 0 else { return }
                let target = sysRMS
                var gain = target / micRMS
                gain = min(max(gain, 0.1), 4.0) // Clamp 0.1-4x to avoid extremes
                DispatchQueue.main.async {
                    self.micMixer.outputVolume = Float(gain)
                    print("[AutoGain] micMixer gain set to \(gain) (micRMS=\(micRMS), sysRMS=\(sysRMS))")
                }
            }
        }
    }

    private func measureRMS(on node: AVAudioNode, duration: TimeInterval, completion: @escaping (Float) -> Void) {
        let bus = 0
        // Ensure node has a valid format; if not, skip measurement
        guard node.outputFormat(forBus: bus).channelCount > 0 else {
            completion(0)
            return
        }
        
        var sumSquares: Float = 0
        var sampleCount: Float = 0

        node.installTap(onBus: bus, bufferSize: 1024, format: nil) { buffer, _ in
            guard let data = buffer.floatChannelData else { return }
            let frames = Int(buffer.frameLength)
            for ch in 0..<Int(buffer.format.channelCount) {
                let ptr = data[ch]
                for i in 0..<frames {
                    let sample = ptr[i]
                    sumSquares += sample * sample
                }
            }
            sampleCount += Float(frames * Int(buffer.format.channelCount))
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + duration) {
            node.removeTap(onBus: bus)
            let rms = sqrt(sumSquares / max(sampleCount, 1))
            completion(rms)
        }
    }
}
