import QuiltwrightUI

let content = WelcomeContent.helloWorld

try expect(content.title == "Hello, Quiltwright!", "Expected hello-world title")
try expect(content.subtitle == "Design your next quilt with SwiftUI.", "Expected hello-world subtitle")

private func expect(_ condition: Bool, _ message: String) throws {
    guard condition else {
        throw CheckFailure(message: message)
    }
}

private struct CheckFailure: Error, CustomStringConvertible {
    let message: String

    var description: String {
        message
    }
}
