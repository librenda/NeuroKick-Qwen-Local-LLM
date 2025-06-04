import Foundation

import Foundation

struct BehaviorCatalog {
    static let shared = BehaviorCatalog()
    
    // MARK: - Multipliers
    let talentMagnet = MultiplierBehavior(
        name: "Talent Magnet",
        definition: "Identifies and utilizes people's unique strengths",
        examples: [
            "Maria, your analytical skills are perfect for leading the AI integration. I'll connect you with the tech team.",
            "I noticed how well you handled the client presentation. Would you be interested in mentoring the new hires on presentation skills?"
        ],
        implications: "Improves retention and grows talent pipeline",
        diminisherCounterpart: "Empire Builder"
    )
    
    let liberator = MultiplierBehavior(
        name: "Liberator",
        definition: "Creates space for others to contribute",
        examples: [
            "Let's hear the risks. Failure here is okay if we learn.",
            "I want to hear everyone's perspective before sharing mine."
        ],
        implications: "Increases psychological safety and creativity",
        diminisherCounterpart: "Tyrant"
    )
    
    let challenger = MultiplierBehavior(
        name: "Challenger",
        definition: "Pushes the team to go further by setting high standards",
        examples: [
            "What if we could double our impact with half the budget?",
            "I know this seems impossible, but let's think about how we might approach it."
        ],
        implications: "Drives innovation and stretches team capabilities",
        diminisherCounterpart: "Know-It-All"
    )
    
    let debateMaker = MultiplierBehavior(
        name: "Debate Maker",
        definition: "Encourages rigorous thinking and discussion",
        examples: [
            "Let's pressure-test this idea. What are the potential flaws?",
            "I'll play devil's advocate for a moment..."
        ],
        implications: "Leads to better decisions through thorough examination",
        diminisherCounterpart: "Decision Maker"
    )
    
    let investor = MultiplierBehavior(
        name: "Investor",
        definition: "Gives ownership and holds people accountable",
        examples: [
            "You own this project. What's your recommended approach?",
            "I trust your judgment on this. Keep me posted on your progress."
        ],
        implications: "Builds accountability and develops leadership",
        diminisherCounterpart: "Micromanager"
    )
    
    // MARK: - Diminishers
    let empireBuilder = DiminisherBehavior(
        name: "Empire Builder",
        definition: "Hoards talent and resources within their team",
        examples: [
            "We can't spare Jake for that project. He's too valuable here.",
            "I need to keep my best people working on my priorities."
        ],
        implications: "Creates silos and causes top performers to quit",
        multiplierCounterpart: "Talent Magnet"
    )
    
    let tyrant = DiminisherBehavior(
        name: "Tyrant",
        definition: "Creates a tense, fearful environment through control",
        examples: [
            "This is how we'll do it. No deviations.",
            "Because I said so, that's why!"
        ],
        implications: "Increases fear and risk-aversion",
        multiplierCounterpart: "Liberator"
    )
    
    let knowItAll = DiminisherBehavior(
        name: "Know-It-All",
        definition: "Believes they have all the answers",
        examples: [
            "That won't work. Here's what we'll do instead.",
            "I've been doing this for 20 years. I know what works."
        ],
        implications: "Stifles innovation and team input",
        multiplierCounterpart: "Challenger"
    )
    
    let decisionMaker = DiminisherBehavior(
        name: "Decision Maker",
        definition: "Makes all decisions unilaterally",
        examples: [
            "I'll make the final call on this.",
            "Don't worry about the details, just execute."
        ],
        implications: "Creates bottlenecks and disempowers team",
        multiplierCounterpart: "Debate Maker"
    )
    
    let micromanager = DiminisherBehavior(
        name: "Micromanager",
        definition: "Overly controls how work gets done",
        examples: [
            "Why didn't you format this slide my way? Let me fix it.",
            "I need daily updates on every task."
        ],
        implications: "Creates dependency and stifles initiative",
        multiplierCounterpart: "Investor"
    )
    
    // MARK: - Accidental Diminishers
    let ideaGuy = AccidentalDiminisherBehavior(
        name: "Idea Guy",
        definition: "Floods the team with too many ideas",
        examples: [
            "I was thinking we could also try A, B, C, D, E, F...",
            "Here's another thought that just came to me..."
        ],
        implications: "Causes idea paralysis rather than sparking ownership",
        improvementTips: [
            "Limit suggestions to 1-2 per meeting",
            "Ask team for their ideas first",
            "Practice active listening before sharing"
        ]
    )
    
    let alwaysOn = AccidentalDiminisherBehavior(
        name: "Always On",
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
    )
    
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
    
    // MARK: - Collections
    var allMultipliers: [MultiplierBehavior] {
        [talentMagnet, liberator, challenger, debateMaker, investor]
    }
    
    var allDiminishers: [DiminisherBehavior] {
        [empireBuilder, tyrant, knowItAll, decisionMaker, micromanager]
    }
    
    var allAccidentalDiminishers: [AccidentalDiminisherBehavior] {
        [ideaGuy, alwaysOn, rescuer, pacesetter, rapidResponder, 
         optimist, protector, strategist, perfectionist]
    }
}