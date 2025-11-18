//
//  ClaudeClient.swift
//  SFGGit
//
//  Created by Roman Volovelskyi on 18/11/2025.
//

import Foundation

struct PRData {
    let title: String
    let message: String
}

class ClaudeClient: ObservableObject {

    private var apiKey: String {
        return UserDefaults.standard.string(forKey: "claudeAPIKey") ?? ""
    }

    private let apiURL = "https://api.anthropic.com/v1/messages"

    private func extractJSON(from text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        }
        
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }

        // If no markdown wrapper, return as is
        return cleaned
    }

    func generatePRData(from diff: String) async -> PRData? {
        guard !apiKey.isEmpty else {
            print("Claude API key not configured")
            return nil
        }
        
        var diff = diff

        guard !diff.isEmpty else {
            print("No diff provided")
            return nil
        }
        
        if diff.count > 5000 {
            diff = String(diff.prefix(5000))
        }

        let systemPrompt = """
        You are a Pull Request generator. Based on the provided git diff, generate a PR title and description in JSON format.

        Rules for PR title:
        - Use imperative mood (e.g., "Add feature" not "Added feature")
        - Keep under 60 characters
        - Use conventional commit types: feature, fix, docs, style, refactor, test
        - Be specific and descriptive

        Rules for PR message:
        - Provide a clear summary of changes
        - Include bullet points of key changes
        - Mention any breaking changes
        - Keep it concise but informative

        Return ONLY valid JSON in this exact format, without markdown or new lines:
        {
          "title": "",
          "message": ""
        }
        """

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-5-20250929",
            "max_tokens": 200,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": "Generate a PR title and message for this diff:\n\n\(diff)"
                ]
            ]
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

            var request = URLRequest(url: URL(string: apiURL)!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return nil
            }

            if httpResponse.statusCode != 200 {
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("API request failed with status \(httpResponse.statusCode): \(errorString)")
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let firstContent = content.first,
                  let text = firstContent["text"] as? String else {
                print("Failed to parse API response")
                return nil
            }

            let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let jsonString = extractJSON(from: cleanText)

            guard let jsonData = jsonString.data(using: .utf8),
                  let prJson = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let title = prJson["title"] as? String,
                  let message = prJson["message"] as? String else {
                print("Failed to parse PR JSON: \(jsonString)")
                return nil
            }

            return PRData(title: title, message: message)

        } catch {
            print("Failed to generate PR data: \(error)")
            return nil
        }
    }
}
