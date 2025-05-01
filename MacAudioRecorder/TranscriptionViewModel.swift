import Foundation
import Combine

/// View-model that bridges Whisper live transcript and DeepSeek analysis.
@available(macOS 12.0, *)
@MainActor
final class TranscriptionViewModel: ObservableObject {
    // Dependencies
    private let transcriber: WhisperTranscriber

    // Published state
    @Published var transcript: String = ""
    @Published var summary: String = ""
    @Published var isAnalyzing = false

    // Persist API key using @AppStorage in view layer – but expose binding here
    @Published var apiKey: String = ""

    private var cancellables = Set<AnyCancellable>()

    init(transcriber: WhisperTranscriber) {
        self.transcriber = transcriber

        // Bridge transcriber's live text -> our transcript property
        transcriber.$liveTranscript
            .receive(on: RunLoop.main)
            .assign(to: &self.$transcript)
    }

    /// Triggers DeepSeek summarisation of current transcript.
    func analyze() {
        guard !transcript.isEmpty, !apiKey.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""

        Task {
            do {
                let result = try await DeepSeekService.shared.analyze(text: transcript, apiKey: apiKey)
                summary = result
            } catch {
                summary = "[Analysis failed: \(error.localizedDescription)]"
            }
            isAnalyzing = false
        }
    }

    /// Performs a general concise summary.
    func summarize() {
        guard !transcript.isEmpty, !apiKey.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""

        Task {
            do {
                let result = try await DeepSeekService.shared.summarize(text: transcript, apiKey: apiKey)
                summary = result
            } catch {
                summary = "[Summary failed: \(error.localizedDescription)]"
            }
            isAnalyzing = false
        }
    }
}
