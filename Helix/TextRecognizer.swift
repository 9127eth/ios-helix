//
//  TextRecognizer.swift
//  Helix
//
//  Created by Richard Waithe on 12/7/24.
//

import Vision
import UIKit
import Network

class TextRecognizer {
    private let openAIService = OpenAIService()
    private let claudeAIService = ClaudeAIService()
    
    func recognizeAndProcessText(from image: UIImage) async throws -> ScannedContactData {
        // First, use Vision framework to extract text
        let extractedText = try await recognizeText(from: image)
        
        // Check if extracted text is empty or only whitespace
        guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(
                domain: "TextRecognizer",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "No text was detected in the image. Please ensure the image contains clear, readable text or try taking another photo."
                ]
            )
        }
        
        // Print raw extracted text for debugging
        print("Raw OCR Text:", extractedText)
        
        // Check for internet connectivity before making API calls
        let isConnected = await checkNetworkConnectivity()
        guard isConnected else {
            throw NSError(
                domain: "TextRecognizer",
                code: -2,
                userInfo: [
                    NSLocalizedDescriptionKey: "No internet connection. Please connect to the internet to use the AI scanning tool."
                ]
            )
        }
        
        // Try OpenAI first, then Claude as fallback
        do {
            let processedData = try await openAIService.processBusinessCard(text: extractedText)
            return convertToScannedData(processedData, image)
        } catch {
            // Check if it's a network error
            if isNetworkError(error) {
                throw NSError(
                    domain: "TextRecognizer",
                    code: -2,
                    userInfo: [
                        NSLocalizedDescriptionKey: "No internet connection. Please connect to the internet to use the AI scanning tool."
                    ]
                )
            }
            
            print("OpenAI processing failed, trying Claude: \(error.localizedDescription)")
            do {
                let processedData = try await claudeAIService.processBusinessCard(text: extractedText)
                return convertToScannedData(processedData, image)
            } catch {
                // Check if it's a network error
                if isNetworkError(error) {
                    throw NSError(
                        domain: "TextRecognizer",
                        code: -2,
                        userInfo: [
                            NSLocalizedDescriptionKey: "No internet connection. Please connect to the internet to use the AI scanning tool."
                        ]
                    )
                }
                
                print("Claude processing failed: \(error.localizedDescription)")
                throw NSError(
                    domain: "TextRecognizer",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to process the text from the image. Please try taking another photo with clearer text."
                    ]
                )
            }
        }
    }
    
    private func checkNetworkConnectivity() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "NetworkMonitor")
            var hasResumed = false
            let lock = NSLock()
            
            monitor.pathUpdateHandler = { path in
                lock.lock()
                defer { lock.unlock() }
                
                guard !hasResumed else { return }
                hasResumed = true
                monitor.cancel()
                continuation.resume(returning: path.status == .satisfied)
            }
            
            monitor.start(queue: queue)
            
            // Timeout after 2 seconds if no response
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                lock.lock()
                defer { lock.unlock() }
                
                guard !hasResumed else { return }
                hasResumed = true
                monitor.cancel()
                continuation.resume(returning: false)
            }
        }
    }
    
    private func isNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        
        // Check for common network error codes
        let networkErrorCodes = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorTimedOut,
            NSURLErrorDNSLookupFailed,
            NSURLErrorDataNotAllowed
        ]
        
        return nsError.domain == NSURLErrorDomain && networkErrorCodes.contains(nsError.code)
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

