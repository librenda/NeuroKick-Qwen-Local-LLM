// Make a new test file if needed, or see Tests-Brenda - this is outdated.

import XCTest
@testable import MacAudioRecorder

final class MacAudioRecorderTests: XCTestCase {
    
    func testBehaviorCatalogLoading() {
        // Given
        let catalog = BehaviorCatalog.shared
        
        // Then - Verify all behaviors are loaded
        XCTAssertEqual(catalog.allMultipliers.count, 5, "Should have 5 multiplier behaviors")
        XCTAssertEqual(catalog.allDiminishers.count, 5, "Should have 5 diminisher behaviors")
        XCTAssertEqual(catalog.allAccidentalDiminishers.count, 9, "Should have 9 accidental diminisher behaviors")
    }
    
    func testFindBehavior() {
        // Given
        let catalog = BehaviorCatalog.shared
        
        // When
        let talentMagnet = catalog.findBehavior(named: "Talent Magnet")
        let nonExistent = catalog.findBehavior(named: "Nonexistent Behavior")
        
        // Then
        XCTAssertNotNil(talentMagnet, "Should find Talent Magnet behavior")
        XCTAssertEqual(talentMagnet?.name, "Talent Magnet", "Found behavior should be Talent Magnet")
        XCTAssertNil(nonExistent, "Should return nil for non-existent behavior")
    }
    
    func testSignalPhrases() {
        // Given
        let catalog = BehaviorCatalog.shared
        
        // When
        let signalPhrases = catalog.allSignalPhrases
        
        // Then
        XCTAssertFalse(signalPhrases.isEmpty, "Should have signal phrases")
        XCTAssertGreaterThan(signalPhrases.count, 50, "Should have many signal phrases")
    }
    
    func testBehavioralAnalysis() async throws {
        // Given
        let service = LocalLLMService()
        let conversation = """
        Manager: We can't spare Jake for that project. He's too valuable here.
        Employee: But this is a great growth opportunity for him.
        Manager: I'll decide what's best for the team. Let's move on.
        """
        
        // When
        let analysis = try await service.behavioralAnalyze(text: conversation)
        
        // Then
        XCTAssertFalse(analysis.isEmpty, "Analysis should not be empty")
        print("\nAnalysis Result:", analysis)
    }
}
