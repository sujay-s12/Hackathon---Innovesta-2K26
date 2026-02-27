import Foundation

enum APIService {
    static let backendURL = "http://172.16.13.3:8000"

    static func processMeeting(fileURL: URL) async throws -> MeetingResult {
        let url = URL(string: "\(backendURL)/process-meeting")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300

        let fileData = try Data(contentsOf: fileURL)
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        print("Audio response: \(String(data: data, encoding: .utf8) ?? "unreadable")")
        do {
            return try JSONDecoder().decode(MeetingResult.self, from: data)
        } catch {
            print("Decode error: \(error)")
            throw error
        }
    }

    static func processImages(fileURLs: [URL]) async throws -> MeetingResult {
        let url = URL(string: "\(backendURL)/process-images")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        var body = Data()
        for (index, fileURL) in fileURLs.enumerated() {
            let imageData = try Data(contentsOf: fileURL)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        print("Image response: \(String(data: data, encoding: .utf8) ?? "unreadable")")
        return try JSONDecoder().decode(MeetingResult.self, from: data)
    }
}

// MARK: - Models
struct MeetingResult: Codable {
    let transcript: String?
    let minutes: [String]?
    let keyDiscussionPoints: [String]?
    let decisions: [Decision]?
    let actionItems: [ActionItem]?

    enum CodingKeys: String, CodingKey {
        case transcript
        case minutes
        case keyDiscussionPoints = "key_discussion_points"
        case decisions
        case actionItems = "action_items"
    }
}

struct Decision: Codable, Hashable {
    let decision: String
    let speaker: String?
}

struct ActionItem: Codable, Hashable {
    let task: String
    let owner: String?
    let deadline: String?
}
