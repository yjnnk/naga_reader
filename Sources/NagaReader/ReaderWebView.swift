import AppKit
import NagaReaderCore
import SwiftUI
import WebKit

struct ReaderWebView: NSViewRepresentable {
    let html: String
    let baseURL: URL?
    let readingMode: ReadingMode
    let chapterHref: String
    let restoredProgress: Double
    let onProgressChanged: (String, Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onProgressChanged: onProgressChanged)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "readingProgress")
        let webView = PagingWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.onPageTurn = { [weak coordinator = context.coordinator] direction in
            coordinator?.turnPage(direction)
        }
        webView.readingMode = readingMode
        context.coordinator.readingMode = readingMode
        context.coordinator.chapterHref = chapterHref
        context.coordinator.restoredProgress = restoredProgress
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
        context.coordinator.chapterHref = chapterHref
        context.coordinator.restoredProgress = restoredProgress

        guard context.coordinator.loadedHTML != html || context.coordinator.loadedBaseURL != baseURL else {
            return
        }

        context.coordinator.loadedHTML = html
        context.coordinator.loadedBaseURL = baseURL
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "readingProgress")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        var loadedHTML: String?
        var loadedBaseURL: URL?
        var readingMode = ReadingMode.paged
        var chapterHref = ""
        var restoredProgress: Double = 0
        private let onProgressChanged: (String, Double) -> Void
        private var notificationObservers: [NSObjectProtocol] = []

        init(onProgressChanged: @escaping (String, Double) -> Void) {
            self.onProgressChanged = onProgressChanged
        }

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
              const pageAdvance = Math.max(1, reader.clientWidth);
              const maxLeft = Math.max(0, reader.scrollWidth - reader.clientWidth);
              const currentPage = Math.round(reader.scrollLeft / pageAdvance);
              const targetLeft = Math.max(0, Math.min(maxLeft, (currentPage + \(multiplier)) * pageAdvance));
              reader.scrollTo({ left: targetLeft, top: 0, behavior: 'auto' });
            })();
            """
            webView?.evaluateJavaScript(script)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let progress = min(max(restoredProgress, 0), 1)
            let script = """
            (function() {
              const reader = document.querySelector('.reader');
              if (!reader) { return; }
              const progress = \(progress);
              const isPaged = getComputedStyle(reader).columnWidth !== 'auto';
              const maxLeft = Math.max(0, reader.scrollWidth - reader.clientWidth);
              const maxTop = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
              if (isPaged) {
                reader.scrollLeft = maxLeft * progress;
              } else {
                window.scrollTo(0, maxTop * progress);
              }
            })();
            """
            webView.evaluateJavaScript(script)
            installProgressReporting(in: webView)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "readingProgress" else {
                return
            }
            let progress: Double
            let messageChapterHref: String
            let rawProgress: Any
            if let payload = message.body as? [String: Any],
               let payloadChapterHref = payload["chapterHref"] as? String,
               let payloadProgress = payload["progress"] {
                messageChapterHref = payloadChapterHref
                rawProgress = payloadProgress
            } else {
                messageChapterHref = chapterHref
                rawProgress = message.body
            }

            if let value = rawProgress as? Double {
                progress = value
            } else if let value = rawProgress as? NSNumber {
                progress = value.doubleValue
            } else {
                return
            }

            onProgressChanged(messageChapterHref, min(max(progress, 0), 1))
        }

        private func installProgressReporting(in webView: WKWebView) {
            let escapedChapterHref = chapterHref
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            let script = """
            (function() {
              if (window.__nagaProgressInstalled) { return; }
              window.__nagaProgressInstalled = true;
              const chapterHref = '\(escapedChapterHref)';
              var pending = false;
              function postProgress() {
                if (pending) { return; }
                pending = true;
                window.requestAnimationFrame(function() {
                  pending = false;
                  const reader = document.querySelector('.reader');
                  if (!reader) { return; }
                  const isPaged = getComputedStyle(reader).columnWidth !== 'auto';
                  const maxLeft = Math.max(0, reader.scrollWidth - reader.clientWidth);
                  const maxTop = Math.max(0, document.documentElement.scrollHeight - window.innerHeight);
                  const progress = isPaged
                    ? (maxLeft === 0 ? 0 : reader.scrollLeft / maxLeft)
                    : (maxTop === 0 ? 0 : window.scrollY / maxTop);
                  window.webkit.messageHandlers.readingProgress.postMessage({
                    chapterHref: chapterHref,
                    progress: progress
                  });
                });
              }
              const reader = document.querySelector('.reader');
              if (reader) { reader.addEventListener('scroll', postProgress, { passive: true }); }
              window.addEventListener('scroll', postProgress, { passive: true });
              window.addEventListener('beforeunload', postProgress);
              postProgress();
            })();
            """
            webView.evaluateJavaScript(script)
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
