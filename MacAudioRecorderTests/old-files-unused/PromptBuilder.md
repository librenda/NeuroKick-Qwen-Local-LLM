class PromptBuilder {
    private let catalog = BehaviorCatalog.shared
    
    func buildSystemPrompt() -> String {
        """
        # ROLE
        You are the "Multiplier–Diminisher Diagnostic Assistant," an expert in evaluating manager-employee communication.
        
        # YOUR TASK
        Analyze conversations to identify the manager's communication patterns, emotional dynamics, and behavioral issues.
        
        # BEHAVIOR TAXONOMY
        \(buildBehaviorTaxonomy())
        
        # ANALYSIS INSTRUCTIONS
        1. For each manager statement, identify if it demonstrates any Multiplier, Diminisher, or Accidental Diminisher behavior
        2. Be precise in your identification - only tag behaviors that clearly match the definitions
        3. For each identified behavior:
           - Specify the exact behavior name
           - Quote the relevant text
           - Explain why it matches the behavior
           - Note the potential impact on the team
        
        # OUTPUT FORMAT
        Use this format for your analysis:
        
        ## Behavior Analysis
        [Behavior Type]: [Behavior Name]
        > [Exact quote]
        - **Why it matters**: [Impact on team]
        - **Suggestion**: [If negative, how to improve]
        """
    }
    
    private func buildBehaviorTaxonomy() -> String {
        var taxonomy = "## MULTIPLIERS (Positive Behaviors)\n"
        
        // Add Multipliers
        for behavior in catalog.allMultipliers {
            taxonomy += "\n### \(behavior.name)\n"
            taxonomy += "**Definition**: \(behavior.definition)\n"
            taxonomy += "**Example**: \"\(behavior.examples.first ?? "")\"\n"
            taxonomy += "**Impact**: \(behavior.implications)\n"
            taxonomy += "**Opposite**: \(behavior.diminisherCounterpart)\n"
        }
        
        // Add Diminishers
        taxonomy += "\n## DIMINISHERS (Negative Behaviors)\n"
        for behavior in catalog.allDiminishers {
            taxonomy += "\n### \(behavior.name)\n"
            taxonomy += "**Definition**: \(behavior.definition)\n"
            taxonomy += "**Example**: \"\(behavior.examples.first ?? "")\"\n"
            taxonomy += "**Impact**: \(behavior.implications)\n"
            taxonomy += "**Alternative**: \(behavior.multiplierCounterpart)\n"
        }
        
        // Add Accidental Diminishers
        taxonomy += "\n## ACCIDENTAL DIMINISHERS (Well-Intentioned but Harmful)\n"
        for behavior in catalog.allAccidentalDiminishers {
            taxonomy += "\n### \(behavior.name)\n"
            taxonomy += "**Definition**: \(behavior.definition)\n"
            taxonomy += "**Example**: \"\(behavior.examples.first ?? "")\"\n"
            taxonomy += "**Why it's harmful**: \(behavior.implications)\n"
            taxonomy += "**How to improve**: \(behavior.improvementTips.joined(separator: "\n- "))\n"
        }
        
        return taxonomy
    }
}