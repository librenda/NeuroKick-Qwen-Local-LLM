import Foundation

// MARK: - Behavior Types
enum BehaviorType: String, CaseIterable {
    case multiplier = "Multiplier"
    case diminisher = "Diminisher"
    case accidentalDiminisher = "Accidental Diminisher"
}

// MARK: - Behavior Protocol
protocol Behavior {
    var type: BehaviorType { get }
    var name: String { get }
    var definition: String { get }
    var examples: [String] { get }
    var implications: String { get }
    var signalPhrases: [String] { get }
    var keyIndicators: [String] { get }
}

// MARK: - Multiplier Behaviors
struct MultiplierBehavior: Behavior {
    let type: BehaviorType = .multiplier
    let name: String
    let definition: String
    let examples: [String]
    let implications: String
    let diminisherCounterpart: String
    let signalPhrases: [String]
    let keyIndicators: [String]
}

// MARK: - Diminisher Behaviors
struct DiminisherBehavior: Behavior {
    let type: BehaviorType = .diminisher
    let name: String
    let definition: String
    let examples: [String]
    let implications: String
    let multiplierCounterpart: String
    let signalPhrases: [String]
    let keyIndicators: [String]
}

// MARK: - Accidental Diminisher Behaviors
struct AccidentalDiminisherBehavior: Behavior {
    let type: BehaviorType = .accidentalDiminisher
    let name: String
    let definition: String
    let examples: [String]
    let implications: String
    let improvementTips: [String]
    let signalPhrases: [String]
    let keyIndicators: [String]
}