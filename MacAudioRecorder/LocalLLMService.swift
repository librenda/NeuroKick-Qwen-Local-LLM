import Foundation

/// Lightweight wrapper around a local Ollama-compatible LLM endpoint (e.g. `ollama serve`) running
/// Gemma-2B Q4_K_M. The request/response schema matches Ollama's `/api/chat` route which is mostly
/// OpenAI-compatible but returns a single `message` object instead of `choices`.
@available(macOS 12.0, *)
struct LocalLLMService {
    static let shared = LocalLLMService()

    // MARK: – Public
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

    /// Performs a behavioural analysis focusing on Multiplying vs Diminishing leadership behaviours.
    func behavioralAnalyze(text: String) async throws -> String {
        // System prompt with detailed behaviour taxonomy
        let systemPrompt = """
        You are a Workplace Relationship Analyst, an expert in evaluating manager-employee communication. You analyze conversations to identify the manager's communication patterns, emotional dynamics, and behavioural-related issues, looking for instances where the manager exhibits behaviours that constitute Multiplying versus Diminishing leadership.

        When analysing, look for behaviours that match the following categories:
        – Multiplying Behaviours: Talent Magnet, Liberator, Challenger, Debate Maker, Investor.
        – Diminishing Behaviours: Empire Builder, Tyrant, Know-It-All, Decision Maker, Micromanager. (Also be mindful of common Accidental Diminishers such as Idea Guy, Always On, Rescuer, Pacesetter, Rapid Responder, Optimist, Protector, Strategist, Perfectionist.)

        If a multiplying or diminishing behaviour is detected, flag it clearly in the report, list the specific behaviour name, and provide the exact quote(s) from the manager that demonstrate it. Offer concise, actionable recommendations on how the manager could reinforce multiplying behaviours or mitigate diminishing behaviours.
        """

        let userPrompt = """
        Analyse the following manager-employee conversation for multiplying vs diminishing behaviours. Produce a concise, structured report (markdown OK) with sections:
        1. Behavioural Findings – each finding should include: behaviour type (Multiplying/Diminishing), specific behaviour name, quote(s).
        2. Overall Impact – brief commentary on how these behaviours affect team performance.
        3. Recommendations – actionable guidance for the manager.
        
        Conversation:
        \(text)
        """

        return try await chat(messages: [
            .init(role: "system", content: systemPrompt),
            .init(role: "user", content: userPrompt)
        ])
    }

    // MARK: – Private helpers
    private let endpoint = URL(string: "http://127.0.0.1:11434/api/chat")!
    private let model    = "qwen3:4b" // "gemma:2b"

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
    }
}
