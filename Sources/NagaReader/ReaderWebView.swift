import AppKit
import NagaReaderCore
import SwiftUI
import WebKit

struct ReaderWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    let readingMode: ReadingMode

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = PagingWebView()
        webView.navigationDelegate = context.coordinator
        webView.onPageTurn = { [weak coordinator = context.coordinator] direction in
            coordinator?.turnPage(direction)
        }
        webView.readingMode = readingMode
        context.coordinator.readingMode = readingMode
        context.coordinator.loadedHTML = html
        context.coordinator.loadedBaseURL = baseURL
        context.coordinator.webView = webView
        context.coordinator.installObservers()
        webView.loadHTMLString(html, baseURL: baseURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if let pagingWebView = webView as? PagingWebView {
            pagingWebView.readingMode = readingMode
        }
        context.coordinator.readingMode = readingMode

        guard context.coordinator.loadedHTML != html || context.coordinator.loadedBaseURL != baseURL else {
            return
        }

        context.coordinator.loadedHTML = html
        context.coordinator.loadedBaseURL = baseURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webView: WKWebView?
        var loadedHTML: String?
        var loadedBaseURL: URL?
        var readingMode = ReadingMode.paged
        private var notificationObservers: [NSObjectProtocol] = []

        func installObservers() {
            guard notificationObservers.isEmpty else {
                return
            }
            notificationObservers.append(NotificationCenter.default.addObserver(
                forName: .readerNextPage,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.turnPage(.next)
            })
            notificationObservers.append(NotificationCenter.default.addObserver(
                forName: .readerPreviousPage,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.turnPage(.previous)
            })
        }

        fileprivate func turnPage(_ direction: PageTurnDirection) {
            guard readingMode == .paged else {
                return
            }
            let multiplier = direction == .next ? 1 : -1
            let script = """
            (function() {
              const reader = document.querySelector('.reader');
              if (!reader) { return; }
              const styles = window.getComputedStyle(reader);
              const columnWidth = parseFloat(styles.columnWidth) || reader.clientWidth;
              const columnGap = parseFloat(styles.columnGap) || 0;
              const pageAdvance = columnWidth + columnGap;
              reader.scrollBy({ left: pageAdvance * \(multiplier), top: 0, behavior: 'instant' });
            })();
            """
            webView?.evaluateJavaScript(script)
        }

        deinit {
            notificationObservers.forEach(NotificationCenter.default.removeObserver)
        }
    }
}

private enum PageTurnDirection {
    case previous
    case next
}

private final class PagingWebView: WKWebView {
    var onPageTurn: ((PageTurnDirection) -> Void)?
    var readingMode = ReadingMode.paged

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        guard readingMode == .paged else {
            super.keyDown(with: event)
            return
        }

        switch event.keyCode {
        case KeyCode.leftArrow:
            onPageTurn?(.previous)
        case KeyCode.rightArrow, KeyCode.space:
            onPageTurn?(.next)
        default:
            super.keyDown(with: event)
        }
    }
}

private enum KeyCode {
    static let leftArrow: UInt16 = 123
    static let rightArrow: UInt16 = 124
    static let space: UInt16 = 49
}

extension Notification.Name {
    static let readerNextPage = Notification.Name("readerNextPage")
    static let readerPreviousPage = Notification.Name("readerPreviousPage")
}
