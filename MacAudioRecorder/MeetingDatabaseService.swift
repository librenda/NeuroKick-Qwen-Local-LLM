// MeetingDatabaseService.swift
import Foundation

/// Service for managing meeting data and backend synchronization
/// Handles the complex task of parsing LLM outputs and storing structured data
@available(macOS 12.0, *)
class MeetingDatabaseService: ObservableObject {
    static let shared = MeetingDatabaseService()
    
    // MARK: - Configuration
    private let baseURL = "http://localhost:3000/api"
    private let session = URLSession.shared
    
    // MARK: - Data Models
    struct Meeting: Codable, Identifiable {
        let id: String
        let timestamp: Date
        let duration: Int
        let audioPath: String
        let status: String
        var transcription: Transcription?
        var summary: Summary?
        var behaviorAnalysis: BehaviorAnalysis?
    }
    
    struct Transcription: Codable {
        let id: String
        let meetingId: String
        let text: String
        let confidence: Double
        let timestamp: Date
    }
    
    struct Summary: Codable {
        let id: String
        let meetingId: String
        let content: String
        let timestamp: Date
    }
    
    struct BehaviorAnalysis: Codable {
        let id: String
        let meetingId: String
        let managerName: String?
        let multiplierCount: Int
        let diminisherCount: Int
        let accidentalDiminisherCount: Int
        let analysisData: [String: Any] // Raw LLM output as JSON
        let trainingRecommendations: String?
        let keyInsights: String?
        let timestamp: Date
        let behaviors: [BehaviorInstance]
        
        // Custom coding for JSON handling
        private enum CodingKeys: String, CodingKey {
            case id, meetingId, managerName, multiplierCount, diminisherCount
            case accidentalDiminisherCount, trainingRecommendations, keyInsights
            case timestamp, behaviors
        }
    }
    
    struct BehaviorInstance: Codable {
        let id: String
        let context: String
        let quote: String
        let behaviorType: BehaviorType
        let specificBehavior: String
        let implications: String
        let timestamp: Date
    }
    
    enum BehaviorType: String, Codable, CaseIterable {
        case multiplier = "MULTIPLIER"
        case diminisher = "DIMINISHER"
        case accidentalDiminisher = "ACCIDENTAL_DIMINISHER"
        
        var displayName: String {
            switch self {
            case .multiplier: return "Multiplier"
            case .diminisher: return "Diminisher"
            case .accidentalDiminisher: return "Accidental Diminisher"
            }
        }
    }
    
    // MARK: - Published State
    @Published var meetings: [Meeting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Creates a new meeting record in the backend
    func createMeeting(audioPath: String, duration: Int) async throws -> Meeting {
        let endpoint = URL(string: "\(baseURL)/meetings")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "audioPath": audioPath,
            "duration": duration
        ]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let meeting = try JSONDecoder().decode(Meeting.self, from: data)
        
        await MainActor.run {
            meetings.append(meeting)
        }
        
        return meeting
    }
    
    /// Stores transcription in the backend
    func storeTranscription(meetingId: String, text: String, confidence: Double) async throws {
        let endpoint = URL(string: "\(baseURL)/meetings/\(meetingId)/transcription")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "text": text,
            "confidence": confidence
        ] as [String : Any]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    /// Stores meeting summary in the backend
    func storeSummary(meetingId: String, content: String) async throws {
        let endpoint = URL(string: "\(baseURL)/meetings/\(meetingId)/summary")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["content": content]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    /// Parses and stores behavioral analysis from LLM output
    func storeBehavioralAnalysis(meetingId: String, llmOutput: String) async throws {
        // Parse the LLM output to extract structured data
        let parsedAnalysis = try parseBehavioralAnalysis(llmOutput: llmOutput)
        
        let endpoint = URL(string: "\(baseURL)/meetings/\(meetingId)/behavioral-analysis")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare payload for backend
        let payload: [String: Any] = [
            "managerName": parsedAnalysis.managerName ?? "",
            "multiplierCount": parsedAnalysis.multiplierCount,
            "diminisherCount": parsedAnalysis.diminisherCount,
            "accidentalDiminisherCount": parsedAnalysis.accidentalDiminisherCount,
            "analysisData": ["rawOutput": llmOutput], // Store raw output for reference
            "trainingRecommendations": parsedAnalysis.trainingRecommendations,
            "keyInsights": parsedAnalysis.keyInsights,
            "behaviors": parsedAnalysis.behaviors.map { behavior in
                [
                    "context": behavior.context,
                    "quote": behavior.quote,
                    "behaviorType": behavior.behaviorType.rawValue,
                    "specificBehavior": behavior.specificBehavior,
                    "implications": behavior.implications
                ]
            }
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    /// Fetches all meetings with their associated data
    func fetchMeetings() async throws {
        await MainActor.run { isLoading = true }
        
        let endpoint = URL(string: "\(baseURL)/meetings")!
        let (data, response) = try await session.data(from: endpoint)
        try validateResponse(response)
        
        let fetchedMeetings = try JSONDecoder().decode([Meeting].self, from: data)
        
        await MainActor.run {
            meetings = fetchedMeetings
            isLoading = false
        }
    }
    
    /// Fetches behavioral trends for analytics
    func fetchBehaviorTrends(days: Int = 30) async throws -> [BehaviorTrend] {
        let endpoint = URL(string: "\(baseURL)/analytics/behavior-trends?days=\(days)")!
        let (data, response) = try await session.data(from: endpoint)
        try validateResponse(response)
        
        return try JSONDecoder().decode([BehaviorTrend].self, from: data)
    }
    
    // MARK: - Private Helpers
    
    /// Parses LLM behavioral analysis output into structured data
    private func parseBehavioralAnalysis(llmOutput: String) throws -> ParsedBehaviorAnalysis {
        // This is a sophisticated parsing function that extracts structured data from LLM text output
        // Implementation would involve regex patterns, natural language processing, and careful parsing
        
        var managerName: String?
        var multiplierCount = 0
        var diminisherCount = 0
        var accidentalDiminisherCount = 0
        var trainingRecommendations: String?
        var keyInsights: String?
        var behaviors: [BehaviorInstance] = []
        
        // Parse manager name (look for "Manager: [Name]" pattern)
        if let managerMatch = llmOutput.range(of: #"Manager:\s*([A-Za-z\s]+)"#, options: .regularExpression) {
            managerName = String(llmOutput[managerMatch]).replacingOccurrences(of: "Manager:", with: "").trimmingCharacters(in: .whitespaces)
        }
        
        // Parse behavior counts from tables or summary sections
        // Look for patterns like "Multipliers: 4", "Diminishers: 2", etc.
        if let multiplierMatch = llmOutput.range(of: #"Multipliers?:\s*(\d+)"#, options: .regularExpression) {
            let countString = String(llmOutput[multiplierMatch]).replacingOccurrences(of: #"Multipliers?:\s*"#, with: "", options: .regularExpression)
            multiplierCount = Int(countString) ?? 0
        }
        
        if let diminisherMatch = llmOutput.range(of: #"Diminishers?:\s*(\d+)"#, options: .regularExpression) {
            let countString = String(llmOutput[diminisherMatch]).replacingOccurrences(of: #"Diminishers?:\s*"#, with: "", options: .regularExpression)
            diminisherCount = Int(countString) ?? 0
        }
        
        if let accidentalMatch = llmOutput.range(of: #"Accidental\s+Diminishers?:\s*(\d+)"#, options: .regularExpression) {
            let countString = String(llmOutput[accidentalMatch]).replacingOccurrences(of: #"Accidental\s+Diminishers?:\s*"#, with: "", options: .regularExpression)
            accidentalDiminisherCount = Int(countString) ?? 0
        }
        
        // Extract training recommendations (usually in a dedicated section)
        if let trainingRange = llmOutput.range(of: #"(?i)training\s+plan|recommendations?:(.+?)(?=\n\n|\Z)"#, options: .regularExpression) {
            trainingRecommendations = String(llmOutput[trainingRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract key insights
        if let insightsRange = llmOutput.range(of: #"(?i)key\s+insights?|findings?:(.+?)(?=\n\n|\Z)"#, options: .regularExpression) {
            keyInsights = String(llmOutput[insightsRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Parse individual behavior instances from tables
        // This would be more complex and involve parsing markdown tables or structured text
        behaviors = parseBehaviorInstances(from: llmOutput)
        
        return ParsedBehaviorAnalysis(
            managerName: managerName,
            multiplierCount: multiplierCount,
            diminisherCount: diminisherCount,
            accidentalDiminisherCount: accidentalDiminisherCount,
            trainingRecommendations: trainingRecommendations,
            keyInsights: keyInsights,
            behaviors: behaviors
        )
    }
    
    /// Parses individual behavior instances from LLM output tables
    private func parseBehaviorInstances(from text: String) -> [BehaviorInstance] {
        var instances: [BehaviorInstance] = []
        
        // Look for table patterns in the LLM output
        // This is a simplified implementation - would need more sophisticated parsing
        let tablePattern = #"\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^|]+)\s*\|"#
        
        text.enumerateMatches(of: tablePattern, options: .regularExpression) { match, _, _ in
            if let match = match, match.numberOfRanges >= 5 {
                let context = String(text[Range(match.range(at: 1), in: text)!]).trimmingCharacters(in: .whitespaces)
                let quote = String(text[Range(match.range(at: 2), in: text)!]).trimmingCharacters(in: .whitespaces)
                let tag = String(text[Range(match.range(at: 3), in: text)!]).trimmingCharacters(in: .whitespaces)
                let implications = String(text[Range(match.range(at: 4), in: text)!]).trimmingCharacters(in: .whitespaces)
                
                // Determine behavior type and specific behavior from tag
                let (behaviorType, specificBehavior) = parseBehaviorTag(tag)
                
                let instance = BehaviorInstance(
                    id: UUID().uuidString,
                    context: context,
                    quote: quote,
                    behaviorType: behaviorType,
                    specificBehavior: specificBehavior,
                    implications: implications,
                    timestamp: Date()
                )
                
                instances.append(instance)
            }
        }
        
        return instances
    }
    
    /// Parses behavior tag to determine type and specific behavior
    private func parseBehaviorTag(_ tag: String) -> (BehaviorType, String) {
        let cleanTag = tag.trimmingCharacters(in: .whitespaces)
        
        // Check for multiplier patterns
        let multiplierBehaviors = ["Talent Magnet", "Liberator", "Challenger", "Debate Maker", "Investor"]
        for behavior in multiplierBehaviors {
            if cleanTag.contains(behavior) {
                return (.multiplier, behavior)
            }
        }
        
        // Check for diminisher patterns  
        let diminisherBehaviors = ["Empire Builder", "Tyrant", "Know-It-All", "Decision Maker", "Micromanager"]
        for behavior in diminisherBehaviors {
            if cleanTag.contains(behavior) {
                return (.diminisher, behavior)
            }
        }
        
        // Check for accidental diminisher patterns
        let accidentalBehaviors = ["Idea Guy", "Always-On", "Rescuer", "Pacesetter", "Rapid Responder", "Optimist", "Protector", "Strategist", "Perfectionist"]
        for behavior in accidentalBehaviors {
            if cleanTag.contains(behavior) {
                return (.accidentalDiminisher, behavior)
            }
        }
        
        // Default fallback
        if cleanTag.contains("(M)") {
            return (.multiplier, cleanTag)
        } else if cleanTag.contains("(D)") {
            return (.diminisher, cleanTag)
        } else if cleanTag.contains("(AD)") {
            return (.accidentalDiminisher, cleanTag)
        }
        
        return (.multiplier, cleanTag) // Default fallback
    }
    
    /// Validates HTTP response and throws appropriate errors
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DatabaseError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw DatabaseError.serverError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Supporting Types
    
    private struct ParsedBehaviorAnalysis {
        let managerName: String?
        let multiplierCount: Int
        let diminisherCount: Int
        let accidentalDiminisherCount: Int
        let trainingRecommendations: String?
        let keyInsights: String?
        let behaviors: [BehaviorInstance]
    }
    
    struct BehaviorTrend: Codable {
        let date: String
        let meetingId: String
        let managerName: String?
        let multipliers: Int
        let diminishers: Int
        let accidentalDiminishers: Int
        let totalBehaviors: Int
        let netScore: Int // multipliers - diminishers
    }
    
    enum DatabaseError: Error, LocalizedError {
        case invalidResponse
        case serverError(Int)
        case parsingError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid server response"
            case .serverError(let code):
                return "Server error: \(code)"
            case .parsingError(let message):
                return "Parsing error: \(message)"
            }
        }
    }
}

// MARK: - String Extension for Regex
extension String {
    func enumerateMatches(of pattern: String, options: NSString.CompareOptions = [], using block: (NSTextCheckingResult?, NSMatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(startIndex..<endIndex, in: self)
            regex.enumerateMatches(in: self, options: [], range: range, using: block)
        } catch {
            print("Regex error: \(error)")
        }
    }
}