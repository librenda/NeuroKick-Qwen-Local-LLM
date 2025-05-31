import Foundation

struct BehaviorCatalog {
    static let shared = BehaviorCatalog()
    
    // MARK: - Multipliers
    let talentMagnet = MultiplierBehavior(
        name: "Talent Magnet",
        definition: "Identifies and utilizes people's unique strengths, assigns stretch roles, and advocates for their growth",
        examples: [
            "Maria, your analytical skills are perfect for leading the AI integration. I'll connect you with the tech team.",
            "Your presentation skills would be valuable for the client pitch. Want to take the lead?",
            "I'm recommending you for the promotion - your leadership on this project has been exceptional."
        ],
        implications: "Improves retention, grows talent pipeline, creates high-performing teams",
        diminisherCounterpart: "Empire Builder",
        signalPhrases: [
            "You're perfect for...",
            "I'll connect you with...",
            "Your skills would be valuable in...",
            "I'm recommending you for...",
            "This stretch assignment would help you..."
        ],
        keyIndicators: [
            "Growth opportunities offered",
            "Recognition of unique strengths",
            "Career advancement support",
            "Cross-functional connections made",
            "Stretch assignments given"
        ]
    )
    
    let liberator = MultiplierBehavior(
        name: "Liberator",
        definition: "Creates psychological safety, encourages debate, tolerates mistakes, and asks 'What's missing?'",
        examples: [
            "Let's hear the risks. Failure here is okay if we learn.",
            "What are we missing in our analysis?",
            "I want to hear dissenting opinions - what concerns you about this approach?",
            "That mistake taught us something valuable. What did we learn?"
        ],
        implications: "Increases psychological safety, boosts creativity, encourages innovation",
        diminisherCounterpart: "Tyrant",
        signalPhrases: [
            "Let's hear the risks",
            "What are we missing?",
            "Failure is okay if we learn",
            "What concerns you about...",
            "I want to hear dissenting opinions"
        ],
        keyIndicators: [
            "Debate encouragement",
            "Mistake tolerance",
            "Learning from failures",
            "Seeking diverse perspectives",
            "Creating safe space for dissent"
        ]
    )
    
    let challenger = MultiplierBehavior(
        name: "Challenger",
        definition: "Asks 'Why not?', reframes problems as questions, sets bold goals, and pushes thinking boundaries",
        examples: [
            "What if we doubled our impact with half the budget?",
            "Why not aim for the seemingly impossible target?",
            "How might we completely reimagine this process?",
            "What would it look like if we were the industry leader in this space?"
        ],
        implications: "Enables breakthrough thinking, drives innovation, pushes beyond comfort zones",
        diminisherCounterpart: "Know-It-All",
        signalPhrases: [
            "What if we...",
            "Why not try...",
            "How might we...",
            "What would it look like if...",
            "What's possible here that we haven't considered?"
        ],
        keyIndicators: [
            "Reframing problems as opportunities",
            "Ambitious goal-setting",
            "Possibility thinking",
            "Boundary-pushing questions",
            "Challenging assumptions"
        ]
    )
    
    let debateMaker = MultiplierBehavior(
        name: "Debate Maker",
        definition: "Delays closure to gather evidence, plays devil's advocate, and ensures rigorous decision-making",
        examples: [
            "Let's pressure-test this with data before deciding.",
            "What's the evidence supporting this approach?",
            "What are the strongest counterarguments to our plan?",
            "Before we commit, let's explore what could go wrong."
        ],
        implications: "Leads to better decisions, increases team buy-in, reduces implementation risks",
        diminisherCounterpart: "Decision Maker",
        signalPhrases: [
            "Let's pressure-test this",
            "What's the evidence?",
            "What are the counterarguments?",
            "Before we commit...",
            "Let's explore what could go wrong"
        ],
        keyIndicators: [
            "Evidence-seeking behavior",
            "Deliberation encouragement",
            "Multiple perspective gathering",
            "Devil's advocate playing",
            "Rigorous analysis promotion"
        ]
    )
    
    let investor = MultiplierBehavior(
        name: "Investor",
        definition: "Transfers ownership, asks 'What do you recommend?', and celebrates effort and learning",
        examples: [
            "This is your call. I trust your judgment.",
            "What do you recommend we do next?",
            "You own this decision - I'm here if you need support.",
            "Great effort on that approach, even though it didn't work out."
        ],
        implications: "Builds ownership mentality, increases scalability, develops decision-making skills",
        diminisherCounterpart: "Micromanager",
        signalPhrases: [
            "This is your call",
            "What do you recommend?",
            "You own this decision",
            "I trust your judgment",
            "You're accountable for..."
        ],
        keyIndicators: [
            "Ownership transfer",
            "Seeking recommendations",
            "Celebrating attempts",
            "Trusting judgment",
            "Supporting from sidelines"
        ]
    )
    
    // MARK: - Diminishers
    let empireBuilder = DiminisherBehavior(
        name: "Empire Builder",
        definition: "Hoards talent and resources, resists internal transfers, prioritizes loyalty over merit",
        examples: [
            "We can't spare Jake for that project. He's too valuable here.",
            "I need people who are loyal to this team first.",
            "That person reports to me - they can't work on other initiatives.",
            "My team needs to focus on my priorities, not company-wide projects."
        ],
        implications: "Creates silos, causes top performers to quit, limits organizational agility",
        multiplierCounterpart: "Talent Magnet",
        signalPhrases: [
            "We can't spare...",
            "They're too valuable here",
            "I need loyal people",
            "My team needs to focus on...",
            "That person reports to me"
        ],
        keyIndicators: [
            "Talent hoarding",
            "Transfer resistance",
            "Loyalty demands over performance",
            "Territorial behavior",
            "Resource monopolization"
        ]
    )
    
    let tyrant = DiminisherBehavior(
        name: "Tyrant",
        definition: "Creates tense environment through micromanagement, punishes errors, dominates discussions",
        examples: [
            "This is how we'll do it. No deviations.",
            "You should have asked me before making that decision.",
            "I don't want to hear excuses - just get it done my way.",
            "Stop questioning the approach and just execute."
        ],
        implications: "Increases fear and risk-aversion, stifles creativity, creates dependency",
        multiplierCounterpart: "Liberator",
        signalPhrases: [
            "This is how we'll do it",
            "No deviations",
            "You should have asked me first",
            "I don't want to hear excuses",
            "Just execute"
        ],
        keyIndicators: [
            "Rigid control",
            "Error punishment",
            "Discussion domination",
            "Authoritarian directives",
            "Questioning suppression"
        ]
    )
    
    let knowItAll = DiminisherBehavior(
        name: "Know-It-All",
        definition: "Dismisses ideas, dominates with past experience, positions self as the expert on everything",
        examples: [
            "That won't work. Here's what we'll do instead.",
            "I've tried that before - it doesn't work.",
            "Let me tell you the right way to handle this.",
            "I have more experience with this than anyone here."
        ],
        implications: "Causes stagnation, increases disengagement, blocks innovation",
        multiplierCounterpart: "Challenger",
        signalPhrases: [
            "That won't work",
            "I've tried that before",
            "Here's what we'll do instead",
            "Let me tell you the right way",
            "I have more experience"
        ],
        keyIndicators: [
            "Idea dismissal",
            "Past experience dominance",
            "Solution imposition",
            "Expertise claims",
            "Alternative blocking"
        ]
    )
    
    let decisionMaker = DiminisherBehavior(
        name: "Decision Maker",
        definition: "Bottlenecks decisions, avoids team input, rushes to closure without debate",
        examples: [
            "We don't have time to discuss. I'll handle it.",
            "I'll decide later - everyone back to work.",
            "Let me think about it and get back to you.",
            "I've already made up my mind on this."
        ],
        implications: "Slows execution, creates dependency, reduces team buy-in",
        multiplierCounterpart: "Debate Maker",
        signalPhrases: [
            "I'll handle it",
            "I'll decide later",
            "We don't have time to discuss",
            "Let me think about it",
            "I've already made up my mind"
        ],
        keyIndicators: [
            "Decision bottlenecking",
            "Debate avoidance",
            "Rushed closure",
            "Input dismissal",
            "Unilateral decision-making"
        ]
    )
    
    let micromanager = DiminisherBehavior(
        name: "Micromanager",
        definition: "Nitpicks work, redoes tasks, demands excessive updates and control over details",
        examples: [
            "Why didn't you format this slide my way? Let me fix it.",
            "Send me updates every hour on your progress.",
            "I need to review every email before you send it.",
            "That's not how I would have done it - redo it."
        ],
        implications: "Creates learned helplessness, reduces efficiency, stifles growth",
        multiplierCounterpart: "Investor",
        signalPhrases: [
            "Why didn't you format this my way?",
            "Let me fix it",
            "Send me updates every hour",
            "I need to review every...",
            "That's not how I would have done it"
        ],
        keyIndicators: [
            "Task redoing",
            "Excessive oversight",
            "Format obsession",
            "Constant check-ins",
            "Detail control"
        ]
    )
    
    // MARK: - Accidental Diminishers
    let ideaGuy = AccidentalDiminisherBehavior(
        name: "Idea Guy",
        definition: "Floods the team with too many ideas, causing paralysis rather than sparking ownership",
        examples: [
            "I was thinking we could also try A, B, C, D, E, F...",
            "Here are 15 different approaches we could take...",
            "What if we combined all these ideas into one mega-solution?",
            "I just thought of another way we could improve this..."
        ],
        implications: "Causes idea paralysis, overwhelms team capacity, prevents deep execution",
        improvementTips: [
            "Limit suggestions to 1-2 per meeting",
            "Ask team for their ideas first",
            "Focus on developing others' ideas instead of adding new ones",
            "Create 'idea parking lots' for future consideration"
        ],
        signalPhrases: [
            "I was thinking we could also...",
            "Here are 15 different approaches...",
            "What if we combined...",
            "I just thought of another way..."
        ],
        keyIndicators: [
            "Rapid-fire idea generation",
            "Multiple simultaneous suggestions",
            "Overwhelming volume of options",
            "Lack of prioritization"
        ]
    )
    
    let alwaysOn = AccidentalDiminisherBehavior(
        name: "Always On",
        definition: "Maintains boundless energy that actually drains and exhausts those around them",
        examples: [
            "This is so exciting! Let's tackle five more projects!",
            "I know it's 8 PM, but I just had this amazing idea...",
            "We should definitely add this to our already packed agenda!",
            "I could talk about this all night - who's with me?"
        ],
        implications: "Exhausts team members, creates unsustainable pace, burns out others",
        improvementTips: [
            "Monitor team energy levels regularly",
            "Schedule dedicated downtime",
            "Ask 'How is everyone feeling?' before adding more",
            "Match your energy to the room's energy"
        ],
        signalPhrases: [
            "This is so exciting!",
            "Let's tackle five more...",
            "I know it's late, but...",
            "I could talk about this all night..."
        ],
        keyIndicators: [
            "Relentless enthusiasm",
            "Energy mismatch with team",
            "Continuous agenda expansion",
            "Ignoring fatigue signals"
        ]
    )
    
    let rescuer = AccidentalDiminisherBehavior(
        name: "Rescuer",
        definition: "Swoops in to solve problems for others, depriving them of growth through struggle",
        examples: [
            "Let me handle that difficult client for you.",
            "Don't worry about the presentation - I'll take care of it.",
            "I can see you're struggling, so I'll just do it myself.",
            "That looks hard - here, let me show you the easy way."
        ],
        implications: "Prevents skill development, creates dependency, robs learning opportunities",
        improvementTips: [
            "Ask 'How can I support you?' instead of taking over",
            "Provide coaching rather than solutions",
            "Let people struggle productively",
            "Celebrate their breakthroughs, not your rescues"
        ],
        signalPhrases: [
            "Let me handle that for you",
            "Don't worry - I'll take care of it",
            "I'll just do it myself",
            "Let me show you the easy way"
        ],
        keyIndicators: [
            "Taking over tasks",
            "Preventing productive struggle",
            "Solution-giving instead of coaching",
            "Dependency creation"
        ]
    )
    
    let pacesetter = AccidentalDiminisherBehavior(
        name: "Pacesetter",
        definition: "Sets relentless pace that prevents others from keeping up or learning sustainably",
        examples: [
            "Come on team, we can move faster than this!",
            "I finished my part in two hours - what's taking everyone else so long?",
            "Let's compress this three-week project into one week.",
            "We don't have time for training - just figure it out as we go."
        ],
        implications: "Creates unsustainable rhythm, prevents proper learning, increases errors",
        improvementTips: [
            "Set realistic timelines with buffer time",
            "Ask about others' capacity before setting pace",
            "Build in learning and reflection time",
            "Celebrate progress over speed"
        ],
        signalPhrases: [
            "Come on, we can move faster",
            "What's taking everyone else so long?",
            "Let's compress this timeline",
            "We don't have time for training"
        ],
        keyIndicators: [
            "Unrealistic timeline setting",
            "Impatience with others' pace",
            "Skipping learning opportunities",
            "Speed over quality focus"
        ]
    )
    
    let rapidResponder = AccidentalDiminisherBehavior(
        name: "Rapid Responder",
        definition: "Provides instant answers, preventing team deliberation and thoughtful consideration",
        examples: [
            "The answer is obviously option B - let's move on.",
            "I know exactly what we should do here...",
            "No need to think about it - I've seen this before.",
            "Quick decision: we'll go with the first option."
        ],
        implications: "Prevents deep thinking, reduces team engagement, misses better solutions",
        improvementTips: [
            "Count to 10 before responding",
            "Ask 'What does everyone else think?' first",
            "Use phrases like 'Let's think about this together'",
            "Value process over speed"
        ],
        signalPhrases: [
            "The answer is obviously...",
            "I know exactly what we should do",
            "No need to think about it",
            "Quick decision..."
        ],
        keyIndicators: [
            "Immediate answer provision",
            "Cutting off deliberation",
            "Process skipping",
            "Speed over depth preference"
        ]
    )
    
    let optimist = AccidentalDiminisherBehavior(
        name: "Optimist",
        definition: "Maintains unshakeable belief that prevents honest risk assessment and realistic planning",
        examples: [
            "Don't worry about the risks - everything will work out fine!",
            "We don't need a backup plan - this will definitely succeed!",
            "Why focus on what could go wrong? Let's think positive!",
            "Those concerns are just negativity - we've got this!"
        ],
        implications: "Leaves teams unprepared for challenges, ignores legitimate concerns, increases failure risk",
        improvementTips: [
            "Ask 'What are we not seeing?' regularly",
            "Create space for honest risk discussion",
            "Balance optimism with realistic planning",
            "Value preparedness alongside positivity"
        ],
        signalPhrases: [
            "Don't worry about the risks",
            "Everything will work out fine",
            "We don't need a backup plan",
            "Those concerns are just negativity"
        ],
        keyIndicators: [
            "Risk dismissal",
            "Unrealistic optimism",
            "Concern minimization",
            "Backup plan avoidance"
        ]
    )
    
    let protector = AccidentalDiminisherBehavior(
        name: "Protector",
        definition: "Shields people from challenges and obstacles, denying them the 'learning edge' that adversity provides",
        examples: [
            "I'll handle the difficult stakeholders - you focus on the easy stuff.",
            "Don't worry about that challenging project - I'll assign it to someone else.",
            "You don't need to be in that tough conversation - I'll represent our team.",
            "Let me shield you from the organizational politics."
        ],
        implications: "Prevents resilience building, limits growth opportunities, creates fragility",
        improvementTips: [
            "Gradually expose people to appropriate challenges",
            "Provide support while maintaining challenge",
            "Ask 'What would help you handle this yourself?'",
            "Build confidence through supported stretch experiences"
        ],
        signalPhrases: [
            "I'll handle the difficult...",
            "Don't worry about that challenging...",
            "You don't need to be in that tough...",
            "Let me shield you from..."
        ],
        keyIndicators: [
            "Challenge avoidance for others",
            "Overprotective behavior",
            "Growth opportunity blocking",
            "Resilience prevention"
        ]
    )
    
    let strategist = AccidentalDiminisherBehavior(
        name: "Strategist",
        definition: "Casts grand visions without tactical grounding, creating analysis paralysis",
        examples: [
            "Let's think about the 50,000-foot view for the next three hours.",
            "Before we get tactical, we need to align on the philosophical framework.",
            "The strategy needs to be perfect before we take any action.",
            "We should analyze every possible scenario before moving forward."
        ],
        implications: "Creates analysis paralysis, delays action, overwhelms with complexity",
        improvementTips: [
            "Balance big picture with concrete next steps",
            "Set time limits for strategic discussions",
            "Ask 'What's the smallest step we could take today?'",
            "Connect vision to immediate actions"
        ],
        signalPhrases: [
            "Let's think about the 50,000-foot view",
            "Before we get tactical...",
            "The strategy needs to be perfect",
            "We should analyze every possible scenario"
        ],
        keyIndicators: [
            "Excessive strategic focus",
            "Action avoidance",
            "Over-analysis tendency",
            "Perfection seeking before action"
        ]
    )
    
    let perfectionist = AccidentalDiminisherBehavior(
        name: "Perfectionist",
        definition: "Focuses on every flaw with endless revisions, demoralizing teams with relentless red-lining",
        examples: [
            "This needs at least three more rounds of revisions before it's ready.",
            "I found 47 things that need to be fixed in this presentation.",
            "Good isn't good enough - it needs to be flawless.",
            "Let me mark up all the issues I see here..."
        ],
        implications: "Demoralizes teams, creates paralysis, prevents timely delivery",
        improvementTips: [
            "Distinguish between 'good enough' and 'perfect'",
            "Set clear quality standards upfront",
            "Celebrate progress and improvements",
            "Focus feedback on the most critical issues only"
        ],
        signalPhrases: [
            "This needs at least three more rounds",
            "I found 47 things that need fixing",
            "Good isn't good enough",
            "Let me mark up all the issues..."
        ],
        keyIndicators: [
            "Endless revision cycles",
            "Excessive flaw-finding",
            "Unrealistic quality standards",
            "Progress paralysis"
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
        [ideaGuy, alwaysOn, rescuer, pacesetter, rapidResponder, optimist, protector, strategist, perfectionist]
    }
    
    // MARK: - Utility Methods
    func findBehavior(named: String) -> (any Behavior)? {
        if let multiplier = allMultipliers.first(where: { $0.name == named }) {
            return multiplier
        }
        if let diminisher = allDiminishers.first(where: { $0.name == named }) {
            return diminisher
        }
        if let accidental = allAccidentalDiminishers.first(where: { $0.name == named }) {
            return accidental
        }
        return nil
    }
    
    var allSignalPhrases: [String: String] {
        var phrases: [String: String] = [:]
        
        for multiplier in allMultipliers {
            for phrase in multiplier.signalPhrases {
                phrases[phrase] = multiplier.name
            }
        }
        
        for diminisher in allDiminishers {
            for phrase in diminisher.signalPhrases {
                phrases[phrase] = diminisher.name
            }
        }
        
        for accidental in allAccidentalDiminishers {
            for phrase in accidental.signalPhrases {
                phrases[phrase] = accidental.name
            }
        }
        
        return phrases
    }
    
    var behaviorPairs: [(MultiplierBehavior, DiminisherBehavior)] {
        [
            (talentMagnet, empireBuilder),
            (liberator, tyrant),
            (challenger, knowItAll),
            (debateMaker, decisionMaker),
            (investor, micromanager)
        ]
    }
}