import Foundation

public struct BookID: Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}

public struct ImportedBookRecord: Equatable, Codable, Identifiable {
    public let id: BookID
    public let title: String
    public let originalFileName: String
    public let storedURL: URL
    public let packagePath: String?
    public let manifest: [String: EPUBManifestItem]
    public let spineHrefs: [String]
    public let chapters: [EPUBChapter]

    public init(
        id: BookID,
        title: String,
        originalFileName: String,
        storedURL: URL,
        packagePath: String? = nil,
        manifest: [String: EPUBManifestItem] = [:],
        spineHrefs: [String] = [],
        chapters: [EPUBChapter] = []
    ) {
        self.id = id
        self.title = title
        self.originalFileName = originalFileName
        self.storedURL = storedURL
        self.packagePath = packagePath
        self.manifest = manifest
        self.spineHrefs = spineHrefs
        self.chapters = chapters
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalFileName
        case storedURL
        case packagePath
        case manifest
        case spineHrefs
        case chapters
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(BookID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        originalFileName = try container.decode(String.self, forKey: .originalFileName)
        storedURL = try container.decode(URL.self, forKey: .storedURL)
        packagePath = try container.decodeIfPresent(String.self, forKey: .packagePath)
        manifest = try container.decodeIfPresent([String: EPUBManifestItem].self, forKey: .manifest) ?? [:]
        spineHrefs = try container.decodeIfPresent([String].self, forKey: .spineHrefs) ?? []
        chapters = try container.decodeIfPresent([EPUBChapter].self, forKey: .chapters) ?? []
    }
}

public enum EPUBImportError: Error, Equatable, LocalizedError {
    case unsupportedFileType
    case couldNotCopyBook
    case couldNotReadBook

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "Apenas arquivos EPUB são suportados."
        case .couldNotCopyBook:
            return "Não foi possível copiar o EPUB para o armazenamento local do app."
        case .couldNotReadBook:
            return "Não foi possível ler este EPUB."
        }
    }
}
