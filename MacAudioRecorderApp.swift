import SwiftUI

@main
struct MacAudioRecorderApp: App {
    var body: some Scene {
        WindowGroup {
            CombinedRecordingView()
                .frame(minWidth: 550, minHeight: 350)
        }
    }
}
