import Foundation
import Combine

/// View-model that bridges Whisper live transcript and enhanced diagnostic analysis (Your Structure)
@available(macOS 12.0, *)
@MainActor
final class TranscriptionViewModel: ObservableObject {
    // Dependencies
    private let transcriber: WhisperTranscriber
    private let localLLMService: LocalLLMService
    private let catalog = BehaviorCatalog.shared

    // Published state
    @Published var transcript: String = ""
    @Published var summary: String = ""
    @Published var isAnalyzing = false
    @Published var analysisProgress: String = ""

    private var cancellables = Set<AnyCancellable>()

    init(transcriber: WhisperTranscriber, localLLMService: LocalLLMService) {
        self.transcriber = transcriber
        self.localLLMService = localLLMService

        // Bridge transcriber's live text -> our transcript property
        transcriber.$liveTranscript
            .receive(on: RunLoop.main)
            .assign(to: &self.$transcript)
    }

    /// Triggers Enhanced Diagnostic Analysis via local LLM
    func enhancedDiagnosticAnalysis() {
        guard !transcript.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""
        analysisProgress = "Initializing advanced diagnostic analysis..."

        Task {
            do {
                analysisProgress = "Analyzing behavioral patterns..."
                let result = try await localLLMService.enhancedDiagnosticAnalysis(text: transcript)
                summary = result
                analysisProgress = "Analysis complete"
            } catch {
                summary = "[Enhanced Analysis failed: \(error.localizedDescription)]"
                analysisProgress = "Analysis failed"
            }
            isAnalyzing = false
        }
    }

    /// Triggers Workplace Analysis via local LLM
    func analyze() {
        guard !transcript.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""
        analysisProgress = "Analyzing workplace dynamics..."

        Task {
            do {
                let result = try await localLLMService.analyze(text: transcript)
                summary = result
                analysisProgress = "Analysis complete"
            } catch {
                summary = "[Analysis failed: \(error.localizedDescription)]"
                analysisProgress = "Analysis failed"
            }
            isAnalyzing = false
        }
    }

    /// Performs a general concise summary via local LLM
    func summarize() {
        guard !transcript.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""
        analysisProgress = "Creating summary..."

        Task {
            do {
                let result = try await localLLMService.summarize(text: transcript)
                summary = result
                analysisProgress = "Summary complete"
            } catch {
                summary = "[Summary failed: \(error.localizedDescription)]"
                analysisProgress = "Summary failed"
            }
            isAnalyzing = false
        }
    }

    /// Performs behavioural analysis via local LLM (now uses enhanced analysis)
    func behavioralAnalyze() {
        guard !transcript.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""
        analysisProgress = "Performing behavioral analysis..."

        Task {
            do {
                let result = try await localLLMService.behavioralAnalyze(text: transcript)
                summary = result
                analysisProgress = "Behavioral analysis complete"
            } catch {
                summary = "[Behavioural analysis failed: \(error.localizedDescription)]"
                analysisProgress = "Analysis failed"
            }
            isAnalyzing = false
        }
    }
    
    /// Quick analysis for immediate insights
    func quickAnalyze() {
        guard !transcript.isEmpty, !isAnalyzing else { return }
        isAnalyzing = true
        summary = ""
        analysisProgress = "Performing quick analysis..."

        Task {
            do {
                let result = try await localLLMService.analyze(text: transcript)
                summary = result
                analysisProgress = "Quick analysis complete"
            } catch {
                summary = "[Quick analysis failed: \(error.localizedDescription)]"
                analysisProgress = "Analysis failed"
            }
            isAnalyzing = false
        }
    }
    
    // MARK: - Behavior Information Access
    
    /// Get information about a specific behavior for UI display
    func getBehaviorInfo(named behaviorName: String) -> (any Behavior)? {
        return catalog.findBehavior(named: behaviorName)
    }
    
    /// Get all multiplier behaviors for UI
    var allMultiplierBehaviors: [MultiplierBehavior] {
        catalog.allMultipliers
    }
    
    /// Get all diminisher behaviors for UI
    var allDiminisherBehaviors: [DiminisherBehavior] {
        catalog.allDiminishers
    }
    
    /// Get all accidental diminisher behaviors for UI
    var allAccidentalDiminisherBehaviors: [AccidentalDiminisherBehavior] {
        catalog.allAccidentalDiminishers
    }
    
    /// Get behavior pairs for comparative display
    var behaviorPairs: [(MultiplierBehavior, DiminisherBehavior)] {
        catalog.behaviorPairs
    }
}