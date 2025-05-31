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

    // Brenda - for text test analysis:
    @Published var testInput: String = ""
    @Published var selectedAnalysisType: AnalysisType = .workplace
    @Published var lastAnalysisType: AnalysisType? // Track last used type

    // Brenda - for text test analysis:
    enum AnalysisType: String, CaseIterable, Identifiable {
        case workplace = "Workplace Analysis"
        case summary = "General Summary"
        case behavioral = "Behavioral Analysis"
        
        var id: String { self.rawValue }
        
        var filePrefix: String {
            switch self {
            case .workplace: return "Workplace"
            case .summary: return "Summary"
            case .behavioral: return "Behavioral"
            }
        }
    }
    // End of Brenda's TEST add-ons
    // Rest of code:

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

    // Brenda: 
    // MARK: - Analysis
    func analyzeTextInput() async {
        let trimmedInput = testInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty, !isAnalyzing else { return }
        
        isAnalyzing = true
        lastAnalysisType = selectedAnalysisType
        summary = "Starting \(selectedAnalysisType.rawValue.lowercased())..."
        
        // Test connection first
        let isConnected = await testOllamaConnection()
        guard isConnected else {
            summary = """
            ❌ Cannot connect to Ollama server.
            
            Please make sure:
            1. Ollama is installed and running
            2. The server is accessible at http://127.0.0.1:11434
            3. You've downloaded the model with: ollama pull qwen3:4b
            """
            isAnalyzing = false
            return
        }
        
        do {
            let result: String
            switch selectedAnalysisType {
            case .workplace:
                result = try await localLLMService.analyze(text: trimmedInput)
            case .summary:
                result = try await localLLMService.summarize(text: trimmedInput)
            case .behavioral:
                result = try await localLLMService.behavioralAnalyze(text: trimmedInput)
            }
            summary = result
        } catch {
            let errorMessage: String
            if let localError = error as? URLError, localError.code == .timedOut {
                errorMessage = "⚠️ \(selectedAnalysisType.rawValue) timed out. The server took too long to respond."
            } else {
                errorMessage = "❌ \(selectedAnalysisType.rawValue) failed: \(error.localizedDescription)"
            }
            summary = errorMessage
            print("Analysis Error: \(error)")
        }
        
        isAnalyzing = false
    }

    // MARK: - Ollama Connection
    private func testOllamaConnection() async -> Bool {
        guard let url = URL(string: "http://127.0.0.1:11434/api/tags") else {
            return false
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            print("Ollama connection test failed: \(error)")
            return false
        }
    }
}
    

    
/*
   // MARK: - File Operations
    func saveAnalysis() {
        let panel = NSSavePanel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        if let lastType = lastAnalysisType {
            panel.nameFieldStringValue = "\(lastType.filePrefix)Analysis-\(timestamp).txt"
        } else {
            panel.nameFieldStringValue = "Analysis-\(timestamp).txt"
        }
        
        panel.allowedContentTypes = [.plainText]
        panel.allowsOtherFileTypes = false
        panel.isExtensionHidden = false
        
        let response = panel.runModal()
        
        guard response == .OK, let url = panel.url else { return }
        
        let analysisType = lastAnalysisType?.rawValue ?? "Analysis"
        let content = """
        === INPUT TEXT ===
        \(testInput)
        
        === \(analysisType.uppercased()) ===
        \(summary)
        """
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save analysis: \(error.localizedDescription)")
        }
    }
*/