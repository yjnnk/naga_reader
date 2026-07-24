import Foundation

public struct EPUBImporter {
    private let storageDirectory: URL
    private let parser: EPUBParser

    public init(storageDirectory: URL, parser: EPUBParser = EPUBParser()) {
        self.storageDirectory = storageDirectory
        self.parser = parser
    }

    public func importBook(from sourceURL: URL) throws -> ImportedBookRecord {
        guard sourceURL.pathExtension.lowercased() == "epub" else {
            throw EPUBImportError.unsupportedFileType
        }

        try FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)

        let title = sourceURL.deletingPathExtension().lastPathComponent
        let id = BookID("\(title.slugified())-\(UUID().uuidString.lowercased())")
        let bookDirectory = storageDirectory.appendingPathComponent(id.rawValue, isDirectory: true)
        let storedURL = bookDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        let temporaryURL = storageDirectory
            .appendingPathComponent(".\(id.rawValue).tmp-\(sourceURL.lastPathComponent)")

        do {
            if FileManager.default.fileExists(atPath: temporaryURL.path) {
                try FileManager.default.removeItem(at: temporaryURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: temporaryURL)
            try FileManager.default.createDirectory(at: bookDirectory, withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: temporaryURL, to: storedURL)
        } catch {
            if FileManager.default.fileExists(atPath: temporaryURL.path) {
                try? FileManager.default.removeItem(at: temporaryURL)
            }
            throw EPUBImportError.couldNotCopyBook
        }

        let parsed: ParsedEPUB
        do {
            parsed = try parser.parse(
                epubURL: storedURL,
                extractingTo: bookDirectory.appendingPathComponent("extracted", isDirectory: true)
            )
        } catch let error as EPUBParseError {
            throw error
        } catch {
            throw EPUBImportError.couldNotReadBook
        }

        return ImportedBookRecord(
            id: id,
            title: parsed.title,
            originalFileName: sourceURL.lastPathComponent,
            storedURL: storedURL,
            packagePath: parsed.packagePath,
            manifest: parsed.manifest,
            spineHrefs: parsed.spineHrefs,
            chapters: parsed.chapters
        )
    }
}

private extension String {
    func slugified() -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        let mapped = lowercased().unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let slug = String(mapped)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return slug.isEmpty ? UUID().uuidString.lowercased() : slug
    }
}
