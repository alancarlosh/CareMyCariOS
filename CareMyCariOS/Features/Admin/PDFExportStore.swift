import Foundation

enum PDFExportStore {
    static func write(data: Data, fileName: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("CareMyCarReports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let url = directory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }
}
