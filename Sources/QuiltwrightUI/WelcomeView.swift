import SwiftUI

public struct WelcomeView: View {
    private let content: WelcomeContent

    public init(content: WelcomeContent = .helloWorld) {
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.3x3.square")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(content.title)
                    .font(.largeTitle.bold())

                Text(content.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
