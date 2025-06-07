import Foundation

/// Lightweight wrapper around the DeepSeek chat-completion endpoint that
/// generates a concise summary of an arbitrary piece of text.
///
/// NOTE: Update the `model` string below if you are using a different DeepSeek
/// model name. The request/response schema follows the OpenAI-compatible
/// interface exposed by DeepSeek.
@available(macOS 12.0, *)
struct DeepSeekService {
    // MARK: – Public API
    static let shared = DeepSeekService()

    /// Sends the supplied text to DeepSeek and returns the summary.
    /// – Parameters:
    ///   - text: Arbitrary text to summarise.
    ///   - apiKey: User-provided DeepSeek API key ("sk-…").
    /// – Returns: Summary string from the LLM.
    func analyze(text: String, apiKey: String) async throws -> String {
        // Build request
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prompt for Workplace Relationship Analyst
        let prompt = """
        Analyze the following workplace conversation between a manager and an employee. Provide a concise report that includes:
        1. **Communication Patterns**: Identify key patterns in tone, clarity, and intent (e.g., directive, vague, supportive).
        2. **Emotional Dynamics**: Highlight emotional undercurrents (e.g., frustration, confidence, disengagement) and their impact on the interaction.
        3. **Performance Issues**: Pinpoint any issues affecting performance, engagement, or alignment with goals (e.g., unclear expectations, mistrust).
        4. **Actionable Recommendations**: Suggest specific strategies for the manager and/or employee to improve communication, trust, or productivity, focusing on work-related outcomes.
        Maintain a professional focus, addressing only workplace dynamics and avoiding personal or therapeutic analysis unless directly relevant to performance. Base your analysis on the following text:\n\n
        \(text)
        """

        let body = RequestBody(
            model: model,
            messages: [
                .init(role: "system",
                      content: "You are a Workplace Relationship Analyst, an expert in evaluating manager-employee communication. You analyze conversations to identify communication patterns, emotional dynamics, and performance-related issues, providing actionable, work-focused recommendations to enhance leadership, engagement, and productivity."),
                .init(role: "user", content: prompt)
            ],
            max_tokens: 512, // Increased to accommodate detailed analysis
            temperature: 0.7 // Slightly higher for nuanced insights
        )
        request.httpBody = try JSONEncoder().encode(body)

        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let raw = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "DeepSeekError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: raw])
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let summary = decoded.choices.first?.message.content else {
            throw NSError(domain: "DeepSeekError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty response"])
        }
        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Performs a general concise summary (original behaviour).
    func summarize(text: String, apiKey: String) async throws -> String {
        // Build request
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = "Summarise the following text in a concise paragraph:\n\n" + text
        let body = RequestBody(
            model: model,
            messages: [
                .init(role: "system", content: "You are a helpful assistant that writes concise summaries."),
                .init(role: "user", content: prompt)
            ],
            max_tokens: 256,
            temperature: 0.5
        )
        request.httpBody = try JSONEncoder().encode(body)

        // Perform request
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let raw = String(data: data, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "DeepSeekError", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: raw])
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let summary = decoded.choices.first?.message.content else {
            throw NSError(domain: "DeepSeekError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty response"])
        }
        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: – Private

    private let endpoint = URL(string: "https://api.deepseek.com/v1/chat/completions")!
    private let model = "deepseek-chat" // Change if you prefer another DeepSeek model

    // MARK: – Request/Response Models
    private struct RequestBody: Codable {
        let model: String
        let messages: [Message]
        let max_tokens: Int?
        let temperature: Double?
    }

    private struct Message: Codable {
        let role: String
        let content: String
    }

    private struct ResponseBody: Codable {
        struct Choice: Codable {
            let message: Message
        }
        let choices: [Choice]
    }
}
