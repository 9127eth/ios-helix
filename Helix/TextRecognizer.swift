//
//  TextRecognizer.swift
//  Helix
//
//  Created by Richard Waithe on 12/7/24.
//

import Vision
import UIKit

class TextRecognizer {
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

