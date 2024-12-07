import SwiftUI
import VisionKit

@available(iOS 16.0, *)
struct DataScannerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isScannerActive = false
    @State private var showingManualEntry = false
    @State private var scannedData = ScannedContactData()
    @State private var recognizedItems: [RecognizedItem] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerViewControllerRepresentable(
                        recognizedItems: $recognizedItems,
                        isScannerActive: $isScannerActive
                    ) { data in
                        handleScannedData(data)
                    }
                } else {
                    ContentUnavailableView(
                        "Scanning Not Available",
                        systemImage: "camera.fill",
                        description: Text("Device doesn't support scanning")
                    )
                }
                
                VStack {
                    Spacer()
                    Button("Continue with Scan") {
                        showingManualEntry = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(scannedData.isEmpty)
                    .padding()
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            CreateContactView(prefilledData: scannedData)
        }
    }
    
    private func handleScannedData(_ text: String) {
        let processor = TextProcessor()
        let processed = processor.processText(text)
        scannedData = processed.data
    }
}

@available(iOS 16.0, *)
struct DataScannerViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var recognizedItems: [RecognizedItem]
    @Binding var isScannerActive: Bool
    var handleScannedText: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ vc: DataScannerViewController, context: Context) {
        if isScannerActive {
            try? vc.startScanning()
        } else {
            vc.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedItems: $recognizedItems, handleScannedText: handleScannedText)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedItems: [RecognizedItem]
        var handleScannedText: (String) -> Void
        
        init(recognizedItems: Binding<[RecognizedItem]>, handleScannedText: @escaping (String) -> Void) {
            self._recognizedItems = recognizedItems
            self.handleScannedText = handleScannedText
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case .text(let text) = item {
                handleScannedText(text.transcript)
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            recognizedItems = allItems
        }
    }
} 