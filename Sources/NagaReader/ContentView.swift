import NagaReaderCore
import SwiftUI

struct ContentView: View {
    private let state = AppShellState.empty

    var body: some View {
        NavigationSplitView {
            List {
                Section(state.sidebarTitle) {
                    Text("Nenhum livro aberto")
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            VStack(spacing: 16) {
                Text(state.readerTitle)
                    .font(.title)
                Text(state.readerMessage)
                    .foregroundStyle(.secondary)
                Button {
                } label: {
                    Label("Abrir EPUB", systemImage: "book")
                }
                .disabled(true)
                .help("Importação será implementada no próximo ticket.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 640)
        .toolbar {
            ToolbarItem {
                Button {
                } label: {
                    Label("Abrir EPUB", systemImage: "book")
                }
                .disabled(true)
                .help("Importação será implementada no próximo ticket.")
            }
        }
    }
}
