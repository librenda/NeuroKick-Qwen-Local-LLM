import Foundation
import Combine

/// View-model that bridges Whisper live transcript and DeepSeek analysis.
@available(macOS 12.0, *)
@MainActor
final class TranscriptionViewModel: ObservableObject {
    // Dependencies
    private let transcriber: WhisperTranscriber
    private let localLLMService: LocalLLMService

    // Published state
    @Published var transcript: String = ""
    @Published var summary: String = ""
    @Published var isAnalyzing = false

    private var cancellables = Set<AnyCancellable>()

    init(transcriber: WhisperTranscriber, localLLMService: LocalLLMService) {
        self.transcriber = transcriber
        self.localLLMService = localLLMService

        // Bridge transcriber's live text -> our transcript property
        transcriber.$liveTranscript
            .receive(on: RunLoop.main)
            .assign(to: &self.$transcript)
    }

    /// Triggers Workplace Analysis via local Gemma model.
    func analyze() {
        guard !transcript.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""

        Task {
            do {
                let result = try await localLLMService.analyze(text: transcript)
                summary = result
            } catch {
                summary = "[Analysis failed: \(error.localizedDescription)]"
            }
            isAnalyzing = false
        }
    }

    /// Performs a general concise summary via local Gemma model.
    func summarize() {
        guard !transcript.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""

        Task {
            do {
                let result = try await localLLMService.summarize(text: transcript)
                summary = result
            } catch {
                summary = "[Summary failed: \(error.localizedDescription)]"
            }
            isAnalyzing = false
        }
    }

    /// Performs behavioural analysis via local Gemma model.
    func behavioralAnalyze() {
        guard !transcript.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""

        Task {
            do {
                let result = try await localLLMService.behavioralAnalyze(text: transcript)
                summary = result
            } catch {
                summary = "[Enhanced behavioural analysis failed: \(error.localizedDescription)]"
            }
            isAnalyzing = false
        }
    }
}
