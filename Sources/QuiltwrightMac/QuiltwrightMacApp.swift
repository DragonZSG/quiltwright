import SwiftUI

#if !XCODE_PROJECT
import QuiltwrightUI
#endif

@main
struct QuiltwrightMacApp: App {
    var body: some Scene {
        WindowGroup {
            WelcomeView()
        }
    }
}
