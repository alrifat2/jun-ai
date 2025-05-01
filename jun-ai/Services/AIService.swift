//
//  AIService.swift
//  jun-ai
//
//  Created by Al Rifat on 4/25/25.
//

import Foundation

class AIService {
    private let apiKey: String
    private let modelName = "gemini-2.0-flash"

    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateYoutubeTitle(transcript: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)") else {
                throw URLError(.badURL)
            }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemInstruction = "Generate a concise and short YouTube title based on the provided transcript. The title should be clear, under 5-10 words if possible, and capture the main idea without unnecessary filler. Return only the title, nothing else."
        
        let prompt = "Please create a title for the following YouTube transcript:\n\n\(transcript)"
        
        let body: [String: Any] = [
            "system_instruction": [
                "parts": [
                    ["text": systemInstruction]
                ]
            ],
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let error = json?["error"] as? [String: Any],
           let errorMessage = error["message"] as? String {
            throw NSError(domain: "GeminiAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    
        if let candidates = json?["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let summary = parts.first?["text"] as? String {
            return summary
        }
        
        throw NSError(domain: "AIServiceError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini response."])
    }
    
    func generateYoutubeSummary(transcript: String) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)") else {
                throw URLError(.badURL)
            }
            
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemInstruction = """
            # System Instructions: YouTube Transcript to Student Notes Converter

            You are an expert educational content summarizer specialized in transforming YouTube video transcripts into high-quality student notes. Your purpose is to help students efficiently grasp key concepts and prepare for exams without needing to rewatch entire videos.

            ## Core Principles:
                - **Educational Focus**: Prioritize learning objectives and key concepts over conversational elements
                - **Academic Precision**: Maintain technical accuracy while making content accessible
                - **Structured Organization**: Present information in a clear, hierarchical format optimized for review

            ## Output Format:
                1. **Key Concepts**: Begin with 3-5 bullet points highlighting the most important takeaways
                2. **Main Content**:
                   - Organize content into logical sections with clear headings and subheadings
                   - Use a hierarchical structure (H2, H3, etc.) to show relationships between concepts
                   - Include important definitions, examples, analogies, and explanations
                   - Preserve important technical terms, formulas, and methodologies
                3. **Summary**: End with a concise paragraph integrating the main ideas

                ## Length Guidelines:
                - Aim for approximately 1/4 to 1/3 of the original transcript length
                - For videos under 10 minutes: 300-500 words
                - For videos 10-20 minutes: 500-800 words
                - For videos over 20 minutes: 800-1200 words
                - Use judgment to adjust based on content density and complexity

            ## Content Selection Priorities:
                1. Core concepts and principles
                2. Key examples that illustrate concepts
                3. Methodologies and processes
                4. Relationships between concepts
                5. Practical applications and implications

            ## Style Guidelines:
                - Use clear, concise academic language appropriate for the subject area
                - Maintain an objective, informative tone
                - Write in third person
                - Use present tense for timeless concepts
                - Break down complex ideas into digestible segments
                - Include bullet points or numbered lists for processes, steps, or related concepts
                - Bold key terms on first mention

            ## Special Instructions:
                - Preserve numerical data, statistics, and evidence
                - Convert informal explanations into proper academic language
                - If transcript contains code examples, preserve essential snippets with proper formatting
                - Format mathematical equations correctly when present
                - Include timestamps for particularly important points (optional)
                - Create meaningful section titles that aid in rapid location of information

            ## Remember:
            Your notes should be comprehensive enough for exam preparation but concise enough to serve as an efficient study aid. Focus on creating a resource that helps students quickly understand and recall the most valuable information from the video.
            """

        let prompt = "Please create student notes from the following YouTube transcript:\n\n\(transcript)"
        
        let body: [String: Any] = [
            "system_instruction": [
                "parts": [
                    ["text": systemInstruction]
                ]
            ],
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        
//        if let rawResponse = String(data: data, encoding: .utf8) {
//            print("🛠 Raw Gemini Response:\n\(rawResponse)")
//        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let error = json?["error"] as? [String: Any],
           let errorMessage = error["message"] as? String {
            throw NSError(domain: "GeminiAPIError", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    
        if let candidates = json?["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let summary = parts.first?["text"] as? String {
            return summary
        }
        
        throw NSError(domain: "AIServiceError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini response."])
    }
    
    func streamGenerateChat(chatHistory: [[String: Any]], summary: String? = nil) async throws -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):streamGenerateContent?alt=sse&key=\(apiKey)") else {
            throw URLError(.badURL)
        }
                
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemInstruction = "You are an expert tutor who helps students understand and learn material. Use the following summary as reference information when answering questions: \n\n\(summary!)\n\nWhen the user asks about a topic that appears in the summary, cite or build on that summary. If the user's question is unrelated, answer normally. All replies must be concise, clear, and in plain language a student can grasp."
        
        let body: [String: Any] = [
            "system_instruction": [
                "parts": [
                    ["text": systemInstruction]
                ]
            ],
            "contents": chatHistory
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        return AsyncThrowingStream { continuation in
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.finish(throwing: NSError(domain: "AIServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                    return
                }
                
                if httpResponse.statusCode != 200 {
                    continuation.finish(throwing: NSError(domain: "AIServiceError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP status code: \(httpResponse.statusCode)"]))
                    return
                }
            }
            
            task.resume()
            
            let session = URLSession.shared
            let streamTask = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let data = data else {
                    continuation.finish(throwing: NSError(domain: "AIServiceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                    return
                }
                
                let responseString = String(decoding: data, as: UTF8.self)
                let events = responseString.components(separatedBy: "data: ")
                
                for event in events {
                    guard !event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                    guard event != "[DONE]" else {
                        continuation.finish()
                        return
                    }
                    
                    do {
                        if let jsonData = event.data(using: .utf8),
                           let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let candidates = json["candidates"] as? [[String: Any]],
                           let content = candidates.first?["content"] as? [String: Any],
                           let parts = content["parts"] as? [[String: Any]],
                           let text = parts.first?["text"] as? String {
                            continuation.yield(text)
                        }
                    } catch {
                        print("Error parsing SSE event: \(error)")
                    }
                }
                
                continuation.finish()
            }
            
            streamTask.resume()
            
            continuation.onTermination = { _ in
                streamTask.cancel()
            }
        }
    }
    
}
