// WhisperTranscriber.swift
// Handles near real-time transcription using local whisper.cpp via direct C API calls.
// Requires whisper.h and libwhisper.dylib to be added to the project,
// and a ggml model (e.g. ggml-base.en.bin) in Application Support.

import Foundation
import AVFoundation

@available(macOS 12.3, *)
final class WhisperTranscriber: ObservableObject {
    // MARK: – Published
    @Published @MainActor var liveTranscript: String = ""   // updates UI

    // MARK: – Private state
    private var converter: AVAudioConverter?
    private let targetFormat: AVAudioFormat = {
        // 16-kHz mono, 16-bit integer PCM, interleaved (required by Whisper)
        var asbd = AudioStreamBasicDescription(
            mSampleRate: 16000,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0
        )
        // Pass a pointer to the ASBD
        return AVAudioFormat(streamDescription: &asbd)!
    }()

    private var audioData = Data()              // raw Float32 PCM for whisper.cpp
    private var timer: DispatchSourceTimer?

    private var whisperContext: OpaquePointer? // C context handle

    // MARK: – Lifecycle
    init() {
        // Load model immediately (can take a few seconds)
        // In a real app, do this on a background thread with progress UI
        guard let modelPath = Self.locateModelPath() else {
            print("[Whisper] Error: Model file not found in Application Support or app bundle. Please place ggml-base.en.bin in ~/Library/Application Support/WhisperModels or add it to the app bundle resources.")
            return
        }
        // Use whisper_init_from_file_with_params if you need custom params
        self.whisperContext = whisper_init_from_file(modelPath)
        if self.whisperContext == nil {
            print("[Whisper] Error: Failed to initialize whisper context from model at \(modelPath)")
        }
    }

    deinit {
        stop()
        if let context = whisperContext {
            whisper_free(context)
        }
    }

    // MARK: – Public API
    func start() {
        audioData.removeAll(keepingCapacity: true)
        Task { @MainActor in liveTranscript = "" } // Clear transcript on main actor
        scheduleTimer()
    }

    func stop() {
        timer?.cancel(); timer = nil
        runTranscription(flush: true)
    }

    func append(buffer: AVAudioPCMBuffer) {
        // Lazy-init converter to match incoming stream format
        if converter == nil {
            // IMPORTANT: Whisper expects Float32, not Int16!
            // Let's adjust targetFormat (we'll convert Int16->Float32 later if needed)
            guard let floatFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                   sampleRate: 16000,
                                                   channels: 1,
                                                   interleaved: false) else { return }
            converter = AVAudioConverter(from: buffer.format, to: floatFormat)
        }
        guard let converter = converter else { return }

        // Allocate output buffer with enough capacity
        let outputFormat = converter.outputFormat
        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let outputFrames = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrames) else { return }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        // Reset converter before use
        converter.reset()
        converter.convert(to: outBuffer, error: &error, withInputFrom: inputBlock)
        guard error == nil, outBuffer.frameLength > 0 else { return }

        // Append Float32 audio data
        let channelCount = Int(outputFormat.channelCount)
        let frameLength = Int(outBuffer.frameLength)
        if let floatChannelData = outBuffer.floatChannelData {
            for channel in 0..<channelCount {
                let channelPtr = floatChannelData[channel]
                // Convert UnsafeMutablePointer<Float> to Data
                let data = Data(buffer: UnsafeBufferPointer(start: channelPtr, count: frameLength))
                audioData.append(data)
            }
        }
    }

    // MARK: – Helper
    private func scheduleTimer() {
        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        t.schedule(deadline: .now() + 5, repeating: 5) // Process every 5 seconds
        t.setEventHandler { [weak self] in self?.runTranscription(flush: false) }
        t.resume()
        timer = t
    }

    private func runTranscription(flush: Bool) {
        guard let context = whisperContext else {
            print("[Whisper] Error: Context not initialized.")
            return
        }
        // Process if we have at least 2 seconds of audio or a flush
        let bytesPerSample = MemoryLayout<Float32>.size
        let minSamples = Int(2 * 16_000) // 2 seconds of Float32 samples
        let minBytes = minSamples * bytesPerSample
        guard flush || audioData.count >= minBytes else { return }

        // Copy & optionally trim buffer (keep last 30 s to bound memory)
        var currentAudioData = audioData
        let maxBytes = 30 * 16_000 * bytesPerSample // 30 seconds max
        if currentAudioData.count > maxBytes {
            currentAudioData = currentAudioData.suffix(maxBytes)
        }
        if !flush { // keep small overlap for context
            let overlapBytes = 2 * 16_000 * bytesPerSample // Keep last 2 seconds
            audioData = currentAudioData.suffix(overlapBytes)
        } else {
            audioData.removeAll()
        }

        // Convert Data -> [Float32]
        let sampleCount = currentAudioData.count / bytesPerSample
        let resultText = currentAudioData.withUnsafeBytes { (bufferPointer: UnsafeRawBufferPointer) -> String in
            guard let baseAddress = bufferPointer.baseAddress else {
                return "[Whisper Error: Could not get buffer base address]"
            }
            let floatPointer = baseAddress.assumingMemoryBound(to: Float32.self)

            // --- Set Whisper parameters ---
            // Use whisper_full_default_params for simplicity, or create manually
            var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)

            // Set common parameters (adjust as needed)
            params.print_realtime = false
            params.print_progress = false
            params.print_timestamps = false
            params.print_special = false
            params.translate = false
            params.language = NSString(string: "en").utf8String // Specify language
            params.n_threads = Int32(max(1, ProcessInfo.processInfo.processorCount / 2)) // Use half the cores
            params.offset_ms = 0
            params.duration_ms = 0
            params.no_context = true // Process audio independently each time for simplicity
            params.single_segment = false

            do {
                // --- Run Inference --- 
                whisper_reset_timings(context) // Optional: Reset timing info
                let ret = whisper_full(context, params, floatPointer, Int32(sampleCount))
                if ret != 0 {
                    return "[Whisper Error: whisper_full failed with code \(ret)]"
                }

                // --- Extract Results --- 
                let n_segments = whisper_full_n_segments(context)
                var combinedText = ""
                for i in 0..<n_segments {
                    if let text_ptr = whisper_full_get_segment_text(context, i) {
                        combinedText += String(cString: text_ptr)
                    }
                }
                whisper_print_timings(context) // Optional: Print timing info to console
                return combinedText.trimmingCharacters(in: .whitespacesAndNewlines)

            } catch {
                return "[Whisper error: \(error.localizedDescription)]"
            }
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if flush {
                // On flush, append final result (maybe add separator?)
                self.liveTranscript += resultText.isEmpty ? "" : "\n" + resultText
            } else {
                // During live transcription, append new text so far
                if !resultText.isEmpty {
                    self.liveTranscript += (self.liveTranscript.isEmpty ? "" : "\n") + resultText
                }
            }
        }
    }

    // MARK: – Model helper
    // Try multiple locations for model file
    static func locateModelPath() -> String? {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        // Ensure directory exists
        let whisperDir = supportDir.appendingPathComponent("WhisperModels") // Changed dir name
        try? FileManager.default.createDirectory(at: whisperDir, withIntermediateDirectories: true)

        let modelURL = whisperDir.appendingPathComponent("ggml-base.en.bin")
        if FileManager.default.fileExists(atPath: modelURL.path) {
            return modelURL.path
        }
        // Fallback: look inside app bundle resources
        if let bundleURL = Bundle.main.resourceURL?.appendingPathComponent("ggml-base.en.bin"),
           FileManager.default.fileExists(atPath: bundleURL.path) {
            return bundleURL.path
        }
        return nil
    }
}
