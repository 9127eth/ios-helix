//
//  TextRecognizer.swift
//  Helix
//
//  Created by Richard Waithe on 12/7/24.
//

import Vision
import UIKit

class TextRecognizer {
    private let openAIService = OpenAIService()
    private let claudeAIService = ClaudeAIService()
    
    func recognizeAndProcessText(from image: UIImage) async throws -> ScannedContactData {
        // First, use Vision framework to extract text
        let extractedText = try await recognizeText(from: image)
        
        // Print raw extracted text for debugging
        print("Raw OCR Text:", extractedText)
        
        // Try OpenAI first, then Claude as fallback
        do {
            let processedData = try await openAIService.processBusinessCard(text: extractedText)
            return convertToScannedData(processedData, image)
        } catch {
            print("OpenAI processing failed, trying Claude: \(error.localizedDescription)")
            do {
                let processedData = try await claudeAIService.processBusinessCard(text: extractedText)
                return convertToScannedData(processedData, image)
            } catch {
                print("Claude processing failed: \(error.localizedDescription)")
                throw NSError(domain: "", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "AI service currently unavailable."])
            }
        }
    }
    
    private func convertToScannedData(_ processedData: OpenAIResponse, _ image: UIImage) -> ScannedContactData {
        var scannedData = ScannedContactData()
        scannedData.name = processedData.name
        scannedData.email = processedData.email
        scannedData.phone = processedData.phone
        scannedData.company = processedData.company
        scannedData.position = processedData.position
        scannedData.website = processedData.website
        scannedData.address = processedData.address
        scannedData.capturedImage = image
        
        scannedData.confidenceScores = [
            "name": 0.9,
            "email": 0.95,
            "phone": 0.9,
            "company": 0.85,
            "position": 0.85,
            "website": 0.9,
            "address": 0.85
        ]
        
        return scannedData
    }
    
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get CGImage"])
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        try await requestHandler.perform([request])
        
        guard let observations = request.results else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No text found"])
        }
        
        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: "\n")
        
        return recognizedText
    }
}

