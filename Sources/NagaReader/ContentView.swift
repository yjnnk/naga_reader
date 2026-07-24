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
            ToolbarItemGroup {
                OpenEPUBButton()
                ReadingSettingsMenu()
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

struct ReadingSettingsMenu: View {
    @EnvironmentObject private var viewModel: ReaderViewModel

    var body: some View {
        Menu {
            Picker("Tema", selection: themeBinding) {
                Text("Claro").tag(ReadingTheme.light)
                Text("Escuro").tag(ReadingTheme.dark)
                Text("Sépia").tag(ReadingTheme.sepia)
            }
            Picker("Modo", selection: modeBinding) {
                Text("Paginação").tag(ReadingMode.paged)
                Text("Rolagem").tag(ReadingMode.scroll)
            }

            Divider()

            Stepper("Largura: \(viewModel.readingSettings.columnWidth) px", value: columnWidthBinding, in: 420...960, step: 20)
            Stepper("Margem: \(viewModel.readingSettings.pageMargin) px", value: marginBinding, in: 24...160, step: 8)
            Stepper("Fonte: \(viewModel.readingSettings.fontSize) px", value: fontSizeBinding, in: 14...32, step: 1)
            Stepper("Linha: \(String(format: "%.2g", viewModel.readingSettings.lineHeight))", value: lineHeightBinding, in: 1.2...2.0, step: 0.05)
        } label: {
            Label("Aparência", systemImage: "textformat.size")
        }
    }

    private var themeBinding: Binding<ReadingTheme> {
        Binding(
            get: { viewModel.readingSettings.theme },
            set: { theme in
                viewModel.updateReadingSettings { settings in
                    settings.with(theme: theme)
                }
            }
        )
    }

    private var modeBinding: Binding<ReadingMode> {
        Binding(
            get: { viewModel.readingSettings.readingMode },
            set: { mode in
                viewModel.updateReadingSettings { settings in
                    settings.with(readingMode: mode)
                }
            }
        )
    }

    private var columnWidthBinding: Binding<Int> {
        Binding(
            get: { viewModel.readingSettings.columnWidth },
            set: { value in
                viewModel.updateReadingSettings { settings in
                    settings.with(columnWidth: value)
                }
            }
        )
    }

    private var marginBinding: Binding<Int> {
        Binding(
            get: { viewModel.readingSettings.pageMargin },
            set: { value in
                viewModel.updateReadingSettings { settings in
                    settings.with(pageMargin: value)
                }
            }
        )
    }

    private var fontSizeBinding: Binding<Int> {
        Binding(
            get: { viewModel.readingSettings.fontSize },
            set: { value in
                viewModel.updateReadingSettings { settings in
                    settings.with(fontSize: value)
                }
            }
        )
    }

    private var lineHeightBinding: Binding<Double> {
        Binding(
            get: { viewModel.readingSettings.lineHeight },
            set: { value in
                viewModel.updateReadingSettings { settings in
                    settings.with(lineHeight: value)
                }
            }
        )
    }
}

struct ReaderDetailView: View {
    @EnvironmentObject private var viewModel: ReaderViewModel
    private let state = AppShellState.empty

    var body: some View {
        if let renderedChapter = viewModel.renderedChapter {
            VStack(spacing: 0) {
                ReaderWebView(
                    html: renderedChapter.html,
                    baseURL: renderedChapter.baseURL,
                    readingMode: viewModel.readingSettings.readingMode,
                    chapterHref: renderedChapter.chapterHref,
                    restoredProgress: renderedChapter.restoredProgress,
                    onProgressChanged: viewModel.updateReadingProgress
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if viewModel.readingSettings.readingMode == .paged {
                    PaginationControls()
                        .padding(.vertical, 12)
                }
            }
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

struct PaginationControls: View {
    var body: some View {
        HStack(spacing: 12) {
            Button {
                NotificationCenter.default.post(name: .readerPreviousPage, object: nil)
            } label: {
                Image(systemName: "chevron.left")
            }
            Button {
                NotificationCenter.default.post(name: .readerNextPage, object: nil)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
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
