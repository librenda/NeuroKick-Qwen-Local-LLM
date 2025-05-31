import Foundation

/// Enhanced LLM service using your BehaviorCatalog structure
@available(macOS 12.0, *)
struct LocalLLMService {
    static let shared = LocalLLMService()
    
    private let catalog = BehaviorCatalog.shared
    
    // MARK: – Public Analysis Methods
    
    func enhancedDiagnosticAnalysis(text: String) async throws -> String {
        let systemPrompt = buildSystemPrompt()
        let userPrompt = buildDiagnosticPrompt(text: text)
        
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

    func behavioralAnalyze(text: String) async throws -> String {
        // Use the enhanced diagnostic analysis
        return try await enhancedDiagnosticAnalysis(text: text)
    }
    
    // MARK: – Private Prompt Building Methods
    
    private func buildSystemPrompt() -> String {
        return """
        You are **Dr. Alexandra Wiseman**, the world's leading Multiplier-Diminisher Diagnostic Specialist. You have:

        - **20+ years** analyzing executive leadership behaviors
        - **Co-authored research** with Liz Wiseman on Multipliers theory
        - **Certified expertise** in organizational psychology (Ph.D. Stanford)
        - **Proven track record** of zero-error diagnostic accuracy across 500+ Fortune 500 assessments
        - **Specialized training** in detecting subtle behavioral patterns and micro-expressions in workplace communication

        Your mission: Produce **forensic-level accuracy** in identifying Multiplying, Diminishing, and Accidental Diminishing behaviors using rigorous systematic analysis.

        \(buildBehaviorTaxonomy())

        **DIAGNOSTIC PROTOCOL:**
        You must follow this exact sequence:

        **STEP 1: SYSTEMATIC EXTRACTION**
        1.1. Identify who is the manager/leader and who are the team members/employees
        1.2. Extract EVERY distinct statement made by the manager with exact quotes
        1.3. Note the immediate context for each statement

        **STEP 2: BEHAVIORAL CLASSIFICATION**
        For each manager statement, apply this analysis:
        - Only assign tags that match our exact taxonomy
        - Require 85%+ confidence to classify
        - Use "UNCLASSIFIED" if uncertain
        - Never invent or modify quotes

        **STEP 3: QUANTITATIVE SCORING**
        Provide exact counts for each behavior type and calculate net tilt score.

        **STEP 4: DIAGNOSTIC SYNTHESIS**
        - Risk assessment (immediate, medium-term, long-term)
        - Intervention priorities (STOP, START, CONTINUE behaviors)
        - Specific training recommendations with exercises and timelines

        **QUALITY CONTROLS:**
        - 95%+ diagnostic accuracy standard
        - Zero tolerance for false positives
        - Conservative classification when uncertain
        """
    }
    
    private func buildBehaviorTaxonomy() -> String {
        var taxonomy = "**BEHAVIORAL TAXONOMY:**\n\n"
        
        // Multiplier Behaviors
        taxonomy += "**MULTIPLIER BEHAVIORS (M):**\n"
        for multiplier in catalog.allMultipliers {
            taxonomy += """
            \(multiplier.name): \(multiplier.definition)
            Signal phrases: \(multiplier.signalPhrases.joined(separator: ", "))
            Example: "\(multiplier.examples.first ?? "")"
            
            """
        }
        
        // Diminisher Behaviors
        taxonomy += "\n**DIMINISHER BEHAVIORS (D):**\n"
        for diminisher in catalog.allDiminishers {
            taxonomy += """
            \(diminisher.name): \(diminisher.definition)
            Signal phrases: \(diminisher.signalPhrases.joined(separator: ", "))
            Example: "\(diminisher.examples.first ?? "")"
            
            """
        }
        
        // Accidental Diminisher Behaviors
        taxonomy += "\n**ACCIDENTAL DIMINISHER BEHAVIORS (AD):**\n"
        for accidental in catalog.allAccidentalDiminishers {
            taxonomy += """
            \(accidental.name): \(accidental.definition)
            Signal phrases: \(accidental.signalPhrases.joined(separator: ", "))
            Example: "\(accidental.examples.first ?? "")"
            
            """
        }
        
        return taxonomy
    }
    
    private func buildDiagnosticPrompt(text: String) -> String {
        return """
        **TRANSCRIPT TO ANALYZE:**
        
        \(text)
        
        **REQUIRED OUTPUT FORMAT:**
        
        **STEP 1 - SYSTEMATIC EXTRACTION:**
        Manager: [Name if identifiable]
        Context: [Meeting type, situation, participants]
        
        Manager Statements:
        1. "[exact quote]" - Context: [situation]
        2. "[exact quote]" - Context: [situation]
        [continue for all statements]
        
        **STEP 2 - BEHAVIORAL CLASSIFICATION:**
        
        For each statement:
        QUOTE: [exact verbatim text]
        POTENTIAL_MATCHES: [list possible classifications]
        CONFIDENCE_CHECK: [reasoning for/against each match]
        FINAL_CLASSIFICATION: [M/D/AD - Specific Type] OR [UNCLASSIFIED]
        CONFIDENCE_SCORE: [1-10]
        REASONING: [detailed explanation]
        
        **STEP 3 - QUANTITATIVE SCORING:**
        
        MULTIPLIER BEHAVIORS:
        - Talent Magnet: [count]
        - Liberator: [count]
        - Challenger: [count]
        - Debate Maker: [count]
        - Investor: [count]
        TOTAL MULTIPLIER: [sum]
        
        DIMINISHER BEHAVIORS:
        - Empire Builder: [count]
        - Tyrant: [count]
        - Know-It-All: [count]
        - Decision Maker: [count]
        - Micromanager: [count]
        TOTAL DIMINISHER: [sum]
        
        ACCIDENTAL DIMINISHER: [count by type]
        
        NET TILT SCORE: [(M-D)/Total] = [percentage]
        
        **STEP 4 - DIAGNOSTIC SYNTHESIS:**
        
        **RISK ASSESSMENT:**
        - Immediate risks (next 30 days): [list]
        - Medium-term risks (3-6 months): [list]
        - Long-term organizational impact: [list]
        
        **INTERVENTION PRIORITIES:**
        1. **STOP behaviors** (highest risk diminishers): [specific recommendations]
        2. **START behaviors** (missing multipliers): [specific recommendations]
        3. **CONTINUE behaviors** (existing strengths): [reinforcement strategies]
        
        **TRAINING RECOMMENDATIONS:**
        [Specific exercises for each identified diminisher, reinforcement strategies for emerging multipliers, sequence and timeline for implementation]
        """
    }

    // MARK: – Private helpers
    private let endpoint = URL(string: "http://127.0.0.1:11434/api/chat")!
    private let model    = "qwen3:4b"

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