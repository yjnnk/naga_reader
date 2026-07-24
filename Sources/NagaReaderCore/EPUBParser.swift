import Foundation

public struct EPUBManifestItem: Equatable, Codable {
    public let id: String
    public let href: String
    public let mediaType: String
    public let properties: String

    public init(id: String, href: String, mediaType: String, properties: String) {
        self.id = id
        self.href = href
        self.mediaType = mediaType
        self.properties = properties
    }
}

public struct EPUBChapter: Equatable, Codable {
    public let title: String
    public let href: String

    public init(title: String, href: String) {
        self.title = title
        self.href = href
    }
}

public struct ParsedEPUB: Equatable {
    public let title: String
    public let packagePath: String
    public let manifest: [String: EPUBManifestItem]
    public let spineHrefs: [String]
    public let chapters: [EPUBChapter]
    public let extractedDirectory: URL
    public let packageBaseDirectory: URL

    public init(
        title: String,
        packagePath: String,
        manifest: [String: EPUBManifestItem],
        spineHrefs: [String],
        chapters: [EPUBChapter],
        extractedDirectory: URL,
        packageBaseDirectory: URL
    ) {
        self.title = title
        self.packagePath = packagePath
        self.manifest = manifest
        self.spineHrefs = spineHrefs
        self.chapters = chapters
        self.extractedDirectory = extractedDirectory
        self.packageBaseDirectory = packageBaseDirectory
    }
}

public enum EPUBParseError: Error, Equatable, LocalizedError {
    case invalidContainer
    case invalidPackage
    case unresolvedSpineItem(String)
    case missingSpine
    case unsupportedFixedLayout
    case couldNotExtractArchive

    public var errorDescription: String? {
        switch self {
        case .invalidContainer:
            return "Este EPUB parece inválido: o container não pôde ser lido."
        case .invalidPackage:
            return "Este EPUB parece inválido: o pacote principal não pôde ser lido."
        case .unresolvedSpineItem(let idref):
            return "Este EPUB parece inválido: o item de leitura \(idref) não existe no manifesto."
        case .missingSpine:
            return "Este EPUB não declara uma sequência de leitura."
        case .unsupportedFixedLayout:
            return "EPUBs de layout fixo ainda não são suportados. Use EPUBs reflowable."
        case .couldNotExtractArchive:
            return "Este arquivo EPUB não pôde ser extraído."
        }
    }
}

public struct EPUBParser {
    public init() {}

    public func parse(epubURL: URL, extractingTo extractionURL: URL) throws -> ParsedEPUB {
        try extract(epubURL: epubURL, to: extractionURL)

        let containerURL = extractionURL.appendingPathComponent("META-INF/container.xml")
        let packagePath = try ContainerParser.parsePackagePath(from: containerURL)
        let packageURL = extractionURL.appendingPathComponent(packagePath)
        let packageBaseURL = packageURL.deletingLastPathComponent()
        let package = try PackageParser.parse(packageURL)

        if package.isFixedLayout {
            throw EPUBParseError.unsupportedFixedLayout
        }

        let spineHrefs = try package.spineIDs.map { idref in
            guard let href = package.manifest[idref]?.href else {
                throw EPUBParseError.unresolvedSpineItem(idref)
            }
            return href
        }
        guard !spineHrefs.isEmpty else {
            throw EPUBParseError.missingSpine
        }

        let navHref = package.manifest.values.first { item in
            item.properties.split(separator: " ").contains("nav")
        }?.href
        let navChapters = try navHref.map { href in
            try NavigationParser.parse(packageBaseURL.appendingPathComponent(href))
        } ?? []
        let chapters = spineHrefs.map { href in
            navChapters.first { normalizedChapterHref($0.href) == normalizedChapterHref(href) }
                .map { EPUBChapter(title: $0.title, href: href) }
                ?? EPUBChapter(title: fallbackTitle(for: href), href: href)
        }

        return ParsedEPUB(
            title: package.title.isEmpty ? epubURL.deletingPathExtension().lastPathComponent : package.title,
            packagePath: packagePath,
            manifest: package.manifest,
            spineHrefs: spineHrefs,
            chapters: chapters,
            extractedDirectory: extractionURL,
            packageBaseDirectory: packageBaseURL
        )
    }

    private func extract(epubURL: URL, to extractionURL: URL) throws {
        if FileManager.default.fileExists(atPath: extractionURL.path) {
            try FileManager.default.removeItem(at: extractionURL)
        }
        try FileManager.default.createDirectory(at: extractionURL, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-qq", epubURL.path, "-d", extractionURL.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw EPUBParseError.couldNotExtractArchive
        }
    }

    private func fallbackTitle(for href: String) -> String {
        normalizedChapterHref(href).split(separator: "/").last?
            .split(separator: ".").first?
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized ?? href
    }
}

private func normalizedChapterHref(_ href: String) -> String {
    let withoutFragment = href.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? href
    return withoutFragment.removingPercentEncoding ?? withoutFragment
}

private struct PackageData {
    let title: String
    let manifest: [String: EPUBManifestItem]
    let spineIDs: [String]
    let isFixedLayout: Bool
}

private final class ContainerParser: NSObject, XMLParserDelegate {
    private var packagePath: String?

    static func parsePackagePath(from url: URL) throws -> String {
        let delegate = ContainerParser()
        let parser = XMLParser(data: try Data(contentsOf: url))
        parser.delegate = delegate

        guard parser.parse(), let packagePath = delegate.packagePath else {
            throw EPUBParseError.invalidContainer
        }

        return packagePath
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "rootfile" {
            packagePath = attributeDict["full-path"]
        }
    }
}

private final class PackageParser: NSObject, XMLParserDelegate {
    private var title = ""
    private var currentText = ""
    private var currentMetaProperty: String?
    private var isReadingTitle = false
    private var manifest: [String: EPUBManifestItem] = [:]
    private var spineIDs: [String] = []
    private var isFixedLayout = false

    static func parse(_ url: URL) throws -> PackageData {
        let delegate = PackageParser()
        let parser = XMLParser(data: try Data(contentsOf: url))
        parser.delegate = delegate

        guard parser.parse() else {
            throw EPUBParseError.invalidPackage
        }

        return PackageData(
            title: delegate.title.trimmingCharacters(in: .whitespacesAndNewlines),
            manifest: delegate.manifest,
            spineIDs: delegate.spineIDs,
            isFixedLayout: delegate.isFixedLayout
        )
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case let name where localName(name) == "title":
            isReadingTitle = true
            currentText = ""
        case "meta":
            currentMetaProperty = attributeDict["property"]
            currentText = ""
            if attributeDict["name"] == "fixed-layout", attributeDict["content"] == "true" {
                isFixedLayout = true
            }
        case "item":
            guard let id = attributeDict["id"], let href = attributeDict["href"] else {
                return
            }
            manifest[id] = EPUBManifestItem(
                id: id,
                href: href,
                mediaType: attributeDict["media-type"] ?? "",
                properties: attributeDict["properties"] ?? ""
            )
        case "itemref":
            if let idref = attributeDict["idref"] {
                spineIDs.append(idref)
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isReadingTitle || currentMetaProperty != nil {
            currentText += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case let name where localName(name) == "title":
            if title.isEmpty {
                title = currentText
            }
            isReadingTitle = false
            currentText = ""
        case "meta":
            if currentMetaProperty == "rendition:layout",
               currentText.trimmingCharacters(in: .whitespacesAndNewlines) == "pre-paginated" {
                isFixedLayout = true
            }
            currentMetaProperty = nil
            currentText = ""
        default:
            break
        }
    }

    private func localName(_ elementName: String) -> String {
        elementName.split(separator: ":").last.map(String.init) ?? elementName
    }
}

private final class NavigationParser: NSObject, XMLParserDelegate {
    private var chapters: [EPUBChapter] = []
    private var currentHref: String?
    private var currentTitle = ""

    static func parse(_ url: URL) throws -> [EPUBChapter] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let delegate = NavigationParser()
        let parser = XMLParser(data: try Data(contentsOf: url))
        parser.delegate = delegate

        guard parser.parse() else {
            return []
        }

        return delegate.chapters
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "a", let href = attributeDict["href"] {
            currentHref = href
            currentTitle = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentHref != nil {
            currentTitle += string
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        guard elementName == "a", let href = currentHref else {
            return
        }

        let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        chapters.append(EPUBChapter(title: title.isEmpty ? href : title, href: href))
        currentHref = nil
        currentTitle = ""
    }
}
