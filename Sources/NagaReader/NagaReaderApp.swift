import SwiftUI

@main
struct NagaReaderApp: App {
    @StateObject private var viewModel = ReaderViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.load()
                }
        }
    }
}
