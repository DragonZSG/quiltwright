public struct WelcomeContent: Equatable, Sendable {
    public let title: String
    public let subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    public static let helloWorld = WelcomeContent(
        title: "Hello, Quiltwright!",
        subtitle: "Design your next quilt with SwiftUI."
    )
}
