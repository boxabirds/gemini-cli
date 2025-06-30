import Foundation

class FileSystemService {
    func listFiles(at path: String) -> [String] {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: path)
        } catch {
            print("Error listing files at path \(path): \(error)")
            return []
        }
    }

    func readFile(at path: String) -> String? {
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            print("Error reading file at path \(path): \(error)")
            return nil
        }
    }
}
