import Foundation

/// Enhanced LLM service using your BehaviorCatalog structure
@available(macOS 12.0, *)
struct LocalLLMService {
    static let shared = LocalLLMService()
    
    private let catalog = BehaviorCatalog.shared
    private let promptBuilder = PromptBuilder()
    
    // MARK: – Public Analysis Methods
    
    func behavioralAnalyze(text: String) async throws -> String {
        let systemPrompt = promptBuilder.buildSystemPrompt()
        let userPrompt = """
        Analyze the following manager-employee conversation. Be thorough but concise.
        
        CONVERSATION:
        \(text)
        
        Please provide your analysis following the specified format.
        """
        
        return try await chat(messages: [
            .init(role: "system", content: systemPrompt),
            .init(role: "user", content: userPrompt)
        ])
    }
    
    func analyze(text: String) async throws -> String {
        let prompt = """
        Analyze the following workplace conversation between a manager and an employee. Provide a concise report that includes:
        1. **Communication Patterns**: Identify key patterns in tone, clarity, and intent (e.g., directive, vague, supportive).
        2. **Emotional Dynamics**: Highlight emotional undercurrents (e.g., frustration, confidence, disengagement) and their impact on the interaction.
        3. **Performance Issues**: Pinpoint any issues affecting performance, engagement, or alignment with goals (e.g., unclear expectations, mistrust).
        4. **Actionable Recommendations**: Suggest specific strategies for the manager and/or employee to improve communication, trust, or productivity, focusing on work-related outcomes.
        Maintain a professional focus, addressing only workplace dynamics and avoiding personal or therapeutic analysis unless directly relevant to performance. Base your analysis on the following text:\n\n
        \(text)
        """

        return try await chat(messages: [
            .init(role: "system", content: "You are a Workplace Relationship Analyst, an expert in evaluating manager-employee communication. You analyze conversations to identify communication patterns, emotional dynamics, and performance-related issues, providing actionable, work-focused recommendations to enhance leadership, engagement, and productivity."),
            .init(role: "user", content: prompt)
        ])
    }

    func summarize(text: String) async throws -> String {
        let prompt = "Summarise the following text in a concise paragraph:\n\n" + text
        return try await chat(messages: [
            .init(role: "system", content: "You are a helpful assistant that writes concise summaries."),
            .init(role: "user", content: prompt)
        ])
    }

    // MARK: – Private helpers
    private let endpoint = URL(string: "http://127.0.0.1:11434/api/chat")!
    private let model = "qwen3:4b"

    private func chat(messages: [Message]) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RequestBody(model: model, messages: messages, stream: false)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let raw = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "LocalLLMError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: raw])
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        return decoded.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: – Codable structs
    private struct RequestBody: Codable {
        let model: String
        let messages: [Message]
        let stream: Bool
    }

    private struct Message: Codable {
        let role: String
        let content: String
    }

    private struct ResponseBody: Codable {
        struct Message: Codable {
            let role: String
            let content: String
        }
        let message: Message
        
        // Optional fields (Brenda's additions)
        let model: String?
        let done: Bool?
        let total_duration: Int?
        let eval_count: Int?
        let created_at: String?
        let done_reason: String?
    }
}