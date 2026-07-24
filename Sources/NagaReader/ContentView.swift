import NagaReaderCore
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var viewModel: ReaderViewModel
    private var state: AppShellState { viewModel.shellState }

    var body: some View {
        NavigationSplitView {
            List {
                Section("Livro atual") {
                    if let book = viewModel.currentBook {
                        Text(book.title)
                    } else {
                        Text("Nenhum livro aberto")
                            .foregroundStyle(.secondary)
                    }
                }

                if !viewModel.tableOfContents.isEmpty {
                    Section("Sumário") {
                        ForEach(viewModel.tableOfContents) { entry in
                            Button {
                                viewModel.selectTableOfContentsEntry(id: entry.id)
                            } label: {
                                HStack {
                                    Text(entry.chapter.title)
                                    Spacer()
                                    if viewModel.isSelectedTableOfContentsEntry(entry) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if !viewModel.library.recentBooks.isEmpty {
                    Section("Recentes") {
                        ForEach(viewModel.library.recentBooks) { book in
                            Text(book.title)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            ReaderDetailView()
        }
        .frame(minWidth: 900, minHeight: 640)
        .toolbar {
            ToolbarItem {
                OpenEPUBButton()
            }
        }
        .alert("Naga Reader", isPresented: errorBinding) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var detailMessage: String {
        guard viewModel.readerSession != nil else {
            return state.readerMessage
        }

        guard let selected = viewModel.selectedChapter else {
            return "Este EPUB não tem capítulos navegáveis."
        }

        return "Capítulo ativo: \(selected.href). A renderização do conteúdo entra no próximo ticket."
    }
}

struct ReaderDetailView: View {
    @EnvironmentObject private var viewModel: ReaderViewModel
    private let state = AppShellState.empty

    var body: some View {
        if let renderedChapter = viewModel.renderedChapter {
            ReaderWebView(html: renderedChapter.html, baseURL: renderedChapter.baseURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 16) {
                Text(viewModel.selectedChapter?.title ?? state.readerTitle)
                    .font(.title)
                Text(detailMessage)
                    .foregroundStyle(.secondary)
                OpenEPUBButton()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var detailMessage: String {
        guard viewModel.readerSession != nil else {
            return state.readerMessage
        }

        guard let selected = viewModel.selectedChapter else {
            return "Este EPUB não tem capítulos navegáveis."
        }

        return "Capítulo ativo: \(selected.href)."
    }
}

struct OpenEPUBButton: View {
    @EnvironmentObject private var viewModel: ReaderViewModel

    var body: some View {
        Button {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.epub]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false

            if panel.runModal() == .OK, let url = panel.url {
                viewModel.importBook(from: url)
            }
        } label: {
            Label("Abrir EPUB", systemImage: "book")
        }
    }
}

extension UTType {
    static let epub = UTType(filenameExtension: "epub")!
}
