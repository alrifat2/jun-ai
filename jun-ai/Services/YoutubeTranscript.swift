//
//  YoutubeTranscript.swift
//  jun-ai
//
//  Created by Al Rifat on 4/25/25.
//

import Foundation

struct TranscriptEntry: Codable {
    let text: String
    let duration: Double
    let offset: Double
}

enum YoutubeTranscriptError: Error, LocalizedError {
    case invalidURL
    case videoIDNotFound
    case captionsMissing
    case transcriptNotAvailable
    case transcriptParseError
    case htmlParseError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid YouTube URL."
        case .videoIDNotFound: return "Unable to extract YouTube video ID."
        case .captionsMissing: return "Captions section missing from HTML."
        case .transcriptNotAvailable: return "Transcript not available for this video."
        case .transcriptParseError: return "Unable to parse transcript."
        case .htmlParseError: return "Could not read YouTube page HTML."
        }
    }
}

class YoutubeTranscript {
    static func fetchTranscript(from videoURL: String) async throws -> [TranscriptEntry] {
        guard let videoID = extractVideoID(from: videoURL) else {
            throw YoutubeTranscriptError.videoIDNotFound
        }

        let headers = ["User-Agent": "Mozilla/5.0"]
        let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
        var request = URLRequest(url: url)
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (htmlData, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: htmlData, encoding: .utf8) else {
            throw YoutubeTranscriptError.htmlParseError
        }

        guard let captionsRange = html.range(of: "\"captions\":") else {
            throw YoutubeTranscriptError.captionsMissing
        }

        let jsonStart = html[captionsRange.upperBound...]
        guard let jsonEnd = jsonStart.range(of: ",\"videoDetails") else {
            throw YoutubeTranscriptError.transcriptNotAvailable
        }

        let captionsJSON = String(jsonStart[..<jsonEnd.lowerBound])
        let fullJSON = "{\"captions\":\(captionsJSON)}"

        guard let jsonData = fullJSON.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let captions = parsed["captions"] as? [String: Any],
              let renderer = captions["playerCaptionsTracklistRenderer"] as? [String: Any],
              let tracks = renderer["captionTracks"] as? [[String: Any]],
              !tracks.isEmpty
        else {
            throw YoutubeTranscriptError.transcriptNotAvailable
        }
        
        let englishTrack = tracks.first { track in
            if let languageCode = track["languageCode"] as? String,
               languageCode.lowercased() == "en" {
                return true
            }
            return false
        }
        
        let selectedTrack = englishTrack ?? tracks.first
        
        guard let urlString = selectedTrack?["baseUrl"] as? String,
              let transcriptURL = URL(string: urlString)
        else {
            throw YoutubeTranscriptError.transcriptNotAvailable
        }

        let (xmlData, _) = try await URLSession.shared.data(from: transcriptURL)
        guard let xml = String(data: xmlData, encoding: .utf8) else {
            throw YoutubeTranscriptError.transcriptParseError
        }

        return parseTranscriptXML(xml)
    }

    private static func extractVideoID(from url: String) -> String? {
        let pattern = "(?:youtube\\.com\\/(?:[^\\/]+\\/.+\\/|(?:v|e(?:mbed)?)\\/|.*[?&]v=)|youtu\\.be\\/)([^\"&?\\/\n]{11})"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: url, options: [], range: NSRange(url.startIndex..., in: url)),
              let range = Range(match.range(at: 1), in: url) else {
            return nil
        }
        return String(url[range])
    }

    private static func parseTranscriptXML(_ xml: String) -> [TranscriptEntry] {
        let pattern = "<text start=\"([^\"]*)\" dur=\"([^\"]*)\">([^<]*)</text>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let matches = regex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))

        return matches.compactMap { match in
            guard match.numberOfRanges == 4,
                  let startRange = Range(match.range(at: 1), in: xml),
                  let durRange = Range(match.range(at: 2), in: xml),
                  let textRange = Range(match.range(at: 3), in: xml) else {
                return nil
            }

            let decodedText = String(xml[textRange])
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")

            return TranscriptEntry(
                text: decodedText,
                duration: Double(xml[durRange]) ?? 0,
                offset: Double(xml[startRange]) ?? 0
            )
        }
    }
}
