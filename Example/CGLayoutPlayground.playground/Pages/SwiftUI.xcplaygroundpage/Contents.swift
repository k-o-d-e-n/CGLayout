import Foundation
import PlaygroundSupport
import SwiftUI

struct SomeView: View {
    var body: some View {
        Text("Hello world!")
    }
}

let viewController = UIHostingController(rootView: SomeView())

PlaygroundPage.current.liveView = viewController
