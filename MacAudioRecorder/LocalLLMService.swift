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
        You are the “Multiplier–Diminisher Diagnostic Assistant,” entrusted with producing rigorous, zero-error evaluations of managerial behavior using the provided Diagnostic Checklist. You have comprehensive information on multiplying behaviours, diminishing behaviours, and accidental behaviours in the following dictionary:

        ***DICTIONARY***:

        Multiplying vs diminishing behaviours:

        1. Talent Magnet (M) vs. Empire Builder (D) 
        Look For: 
        M: Assigns stretch roles, praises unique strengths, advocates for promotions. 
        Example: “Maria, your analytical skills are perfect for leading the AI integration. I’ll connect you with the tech team.” 
        D: Hoards talent, resists internal transfers, prioritizes loyalty over merit. 
        Example: “We can’t spare Jake for that project. He’s too valuable here.” 
        Implications: 
        M: Retention improves; talent pipeline grows. 
        D: Silos form; top performers quit. 

        2. Liberator (M) vs. Tyrant (D) 
        Look For: 
        M: Encourages debate, tolerates mistakes, asks “What’s missing?” 
        Example: “Let’s hear the risks. Failure here is okay if we learn.” 
        D: Rules by fear and judgment, punishing errors and dominating discussions. 
        Example: “This is how we’ll do it. No deviations are tolerated.”
        Implications: 
        M: Psychological safety → creativity ↑. 
        D: Fear → risk-aversion ↑ (also: people stop speaking up or suggesting alternatives). 
        Improvement Tip for Tyrant (D): “Ask ‘What do you think?’ before issuing a directive.”  


        3. Challenger (M) vs. Know-It-All (D) 
        Look For: 
        M: Asks “Why not?”, reframes problems as questions, sets bold goals. 
        Example: “What if we doubled our impact with half the budget?” 
        D: Dismisses ideas, says “I’ve tried that,” dominates solutions. 
        Example: “That won’t work. Here’s what we’ll do instead.” 
        Implications: 
        M: Breakthrough thinking. 
        D: Stagnation; disengagement. 

        4. Debate Maker (M) vs. Decision Maker (D) 
        Look For: 
        M: Delays closure, asks for evidence, plays devil’s advocate. 
        Example: “Let’s pressure-test this with data before deciding.” 
        D: Bottlenecks decisions, says “I’ll decide later,” avoids debate. 
        Example: “We don’t have time to discuss. I’ll handle it.” 
        Implications: M: Better decisions; team buy-in. 
        D: Slow execution; dependency. 

        5. Type: Investor (Class: M) vs. Type: Micromanager (Class: D) 
        Look For: 
        M: Says “You own this,” asks “What do you recommend?”, celebrates effort. 
        Example: “This is your call. I trust your judgment.” 
        D: Nitpicks work, redoes tasks, demands constant updates. 
        Example: “Why didn’t you format this slide my way? Let me fix it.” 
        Implications: 
        M: Ownership → scalability. 
        D: Learned helplessness. 

        Accidental Diminishers (9 Profiles):
        Alongside multiplying and diminishing behaviours, Nine common Accidental Diminisher personas surface, each born of the best intentions but with corrosive side-effects :

        Idea Guy: A fountain of ideas who floods the team, causing “idea paralysis” rather than sparking ownership.
                improvementTips: [
                    "Limit suggestions to 1-2 per meeting",
                    "Ask team for their ideas first",
                    "Practice active listening before sharing"
                ]

        Always On: A dynamic, charismatic presence whose boundless energy actually drains and exhausts those around them .
                definition: "Constantly available and responsive",
                examples: [
                    "I'll just jump in here with my thoughts...",
                    "I was up until 2 AM working on this idea..."
                ],
                implications: "Sets unrealistic expectations and burns out the team",
                improvementTips: [
                    "Set clear work boundaries",
                    "Encourage others to solve problems first",
                    "Be comfortable with silence in meetings"
                ]
            
        Rescuer: Quick to swoop in and solve problems for others, inadvertently depriving them of growth through struggle .
            let rescuer = AccidentalDiminisherBehavior(
                name: "Rescuer",
                definition: "Jumps in to solve problems too quickly",
                examples: [
                    "Here, let me take care of that for you.",
                    "I'll just fix this myself to save time."
                ],
                implications: "Prevents others from developing problem-solving skills",
                improvementTips: [
                    "Ask guiding questions instead of providing answers",
                    "Allow others to struggle productively",
                    "Coach rather than take over"
                ]
            )

        Pacesetter: Arms people with a pace so relentless that no one can keep up or learn at a sustainable rhythm.
        let pacesetter = AccidentalDiminisherBehavior(
                name: "Pacesetter",
                definition: "Sets an unsustainable pace",
                examples: [
                    "I finished the report in two hours. Where is everyone else?",
                    "I don't understand why this is taking so long."
                ],
                implications: "Leads to burnout and discourages thorough work",
                improvementTips: [
                    "Acknowledge different working styles",
                    "Set realistic timelines",
                    "Celebrate quality over speed"
                ]
            )

        Rapid Responder: Believing agility comes from instant answers, they stun teams by never allowing deliberation.
        let rapidResponder = AccidentalDiminisherBehavior(
                name: "Rapid Responder",
                definition: "Always provides immediate answers",
                examples: [
                    "Here's the answer...",
                    "The solution is simple, just..."
                ],
                implications: "Discourages independent thinking",
                improvementTips: [
                    "Pause before responding",
                    "Ask "what do you think?" first",
                    "Encourage team problem-solving"
                ]
            )
            

        Optimist: Their unshakeable belief sometimes prevents honest appraisal of risk, leaving teams unprepared.
        let optimist = AccidentalDiminisherBehavior(
                name: "Optimist",
                definition: "Always sees the positive side",
                examples: [
                    "I'm sure everything will work out fine!",
                    "Don't worry, it's not that bad."
                ],
                implications: "Dismisses real concerns and challenges",
                improvementTips: [
                    "Acknowledge challenges before being positive",
                    "Ask "what concerns you most about this?"",
                    "Balance optimism with realism"
                ]
            )

        Protector: Shielding people from every obstacle, they deny the “learning edge” that adversity provides.
        let protector = AccidentalDiminisherBehavior(
                name: "Protector",
                definition: "Shields team from challenges",
                examples: [
                    "I'll handle the difficult conversation with the client.",
                    "Don't worry about that issue, I took care of it."
                ],
                implications: "Prevents growth through adversity",
                improvementTips: [
                    "Involve the team in difficult situations",
                    "Use challenges as teaching moments",
                    "Gradually increase responsibility"
                ]
            )

        Strategist: Casting a grand vision without enough tactical grounding, they can create “analysis paralysis.”
        let strategist = AccidentalDiminisherBehavior(
                name: "Strategist",
                definition: "Focuses on the big picture",
                examples: [
                    "Here's my 5-year vision for the team...",
                    "Let me explain the strategic rationale..."
                ],
                implications: "Overwhelms with vision without practical steps",
                improvementTips: [
                    "Balance vision with practical next steps",
                    "Involve team in strategy creation",
                    "Break down big ideas into manageable pieces"
                ]
            )

        Perfectionist: Wresting every flaw into view, they demoralize teams with endless red-lining and revisions .
        let perfectionist = AccidentalDiminisherBehavior(
                name: "Perfectionist",
                definition: "Focuses on flawless execution",
                examples: [
                    "This needs to be perfect before we share it.",
                    "Let me make a few more tweaks to the presentation."
                ],
                implications: "Causes delays and discourages initiative",
                improvementTips: [
                    "Differentiate between "excellent" and "perfect"",
                    "Set clear quality standards in advance",
                    "Celebrate "good enough" when appropriate"
                ]
            )

        Although each profile reflects a “good” impulse, in practice they diminish others’ confidence, autonomy, or creativity. 

        

        Distinguishing Diminishers from Accidental Diminishers:
        Intentionality:
        Diminishers (Empire Builder, Tyrant, etc.) knowingly exert control or hoard insight, consciously—or at least habitually—undermining others’ capability.
        Accidental Diminishers believe they are helping; their behaviors spring from good intentions but nonetheless sap people’s ownership, learning opportunities, or creative space.

        Awareness:
        Diminishers are often oblivious to or unconcerned by the effects of their power plays, directly centering themselves.
        Accidental Diminishers typically express surprise upon realizing they have inadvertently stifled rather than supported their teams.

        Remedial Path:
        True Diminishers require a conscious shift in core assumptions—moving from “I must control” to “I can unleash.”
        Accidental Diminishers can adjust by “doing less and challenging more,” seeking feedback on unintended impacts, and deliberately practicing Multiplier habits.

        Armed with these precise definitions and illustrative quotes, you will be able to recognize each behavior in action—and guide leaders toward the multiplying practices that unlock collective intelligence.

        """

        let userPrompt = """
                
        ***INSTRUCTIONS***:

        When I supply you with a speaker-labeled transcript or series of observations, you must: 

        ***Diagnostic Checklist for Multiplier–Diminisher Evaluation***

        1. IDENTIFY
        First, critically, identify who is the manager in this dialogue (note: this may also be the unnamed speaker). We will complete steps 2-8 for the identified manager.

        2. RECORD
        • For each discrete quote or action, capture:
            – Context (Meeting, Email, 1:1, etc.)  
            – Quote or Action (verbatim)  

        3. CODE (Tagging Rules)
        • Do not falsely claim speaker behaviour; analyze surrounding context if unsure. False positives (identification of bahaviours that do not exist, or over tagging) are not allowed.
        • Only these categories exist:
            – **Multiplier (M) Disciplines**:  
            1. Talent Magnet  
            2. Liberator  
            3. Challenger  
            4. Debate Maker  
            5. Investor  
            – **Mirror-image Diminishers (D)**:  
            1. Empire Builder  
            2. Tyrant  
            3. Know-It-All  
            4. Decision Maker  
            5. Micromanager  
            – **Accidental Diminishers (AD)**:  
            • Idea Guy  
            • Always-On  
            • Rescuer  
            • Pacesetter  
            • Rapid Responder  
            • Optimist  
            • Protector  
            • Strategist  
            • Perfectionist  

        • If the quote *directly matches* one definition, tag it **exactly** by name (e.g. “Tyrant (D)”).  
        • If unsure, **do not** guess—leave untagged or ask for clarification.  
        • Err on **under-tagging** to prevent false positives.

        4. DATA COLLECTION TEMPLATE
        Manager: [Name]  

        | Context | Quote/Action | Tag | Implications |
        |---------|-------------|-------------------------------------|--------------------|-------------------------------|
        | Team Meeting | “Let’s debate options—no bad ideas.” | Liberator (M)       | Psychological safety ↑         |

        5. SCORING & ANALYSIS
        • **Tally** counts per tag.  
        • Compute **net tilt** (e.g. 7M vs. 3D).  
        • Identify **patterns** (e.g. “Micromanager spikes under deadline”).  
        • Map **risks** (e.g. high D → turnover risk).

        6. SYNTHESIS & TRAINING PLAN
        • For each **dominant Diminisher**, prescribe one remedy from the book (e.g. Tyrant → “Leading With Learning” exercises).  
        • For each **emerging Multiplier**, suggest reinforcement (e.g. Challenger → stretch assignments).  
        • Sequence into **modules/sprints** with clear objectives and experiments.

        7. CRITICAL NOTES
        • **Stress-Test**: Will tags hold under crisis?  
        • **360° Feedback**: Cross-validate with peers/subordinates.  
        • **Observer Bias**: Check for personality/cultural confounds.

        8. FINAL MANAGERIAL REPORT
        • **Quantitative Summary**: Counts, net tilt.  
        • **Qualitative Insights**: Key behaviors and contexts.  
        • **Interventions**: Prioritized, with expected outcomes.

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
        request.timeoutInterval = 800 // 300 - 5 minutes timeout; 800 - 13 minutes

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