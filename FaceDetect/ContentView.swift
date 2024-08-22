//
//  ContentView.swift
//  FaceDetect
//
//  Created by Ricardo on 21/08/24.
//

import SwiftUI
import Vision

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack {
            if let outputImage = viewModel.outputImage {
                Image(uiImage: outputImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("test")
                    .resizable()
                    .scaledToFit()
            }
        }
        .padding()
        .task {
            if let testImage = UIImage(named: "test")?.cgImage {
                await viewModel.detectFaces(testImage)
            }
        }
    }
}

extension ContentView {
    class ViewModel: ObservableObject {
        @Published var outputImage: UIImage?

        func detectFaces(_ image: CGImage) async {
            let request = VNDetectFaceRectanglesRequest() // Create a request for detecting face rectangles
            let handler = VNImageRequestHandler(cgImage: image, options: [:]) // Create a handler for the image
            
            do {
                try handler.perform([request])
                
                if let results = request.results, !results.isEmpty {
                    outputImage = addFaceRectsToImage(results: results, in: image)
                }
            } catch {
                // Handle any errors that occur during face detection
                print("Error performing face detection: \(error)")
            }
        }

        // Draw rectangles around detected faces on the image
        private func addFaceRectsToImage(results: [VNFaceObservation], in image: CGImage) -> UIImage? {
            let uiImage = UIImage(cgImage: image) // Convert CGImage to UIImage
            let imageSize = CGSize(width: uiImage.size.width, height: uiImage.size.height)
            
            UIGraphicsBeginImageContext(imageSize) // Start a new image context
            uiImage.draw(at: .zero) // Draw the original image
            
            let context = UIGraphicsGetCurrentContext()! // Get the current graphics context
            context.setStrokeColor(UIColor.red.cgColor) // Set the stroke color to red
            context.setLineWidth(2.0) // Set the line width for the rectangles
            
            // Loop through all detected faces and draw rectangles around them
            for face in results {
                let boundingBox = face.boundingBox
                let scaledBox = CGRect(
                    x: boundingBox.origin.x * imageSize.width,
                    y: (1 - boundingBox.origin.y - boundingBox.size.height) * imageSize.height,
                    width: boundingBox.size.width * imageSize.width,
                    height: boundingBox.size.height * imageSize.height
                )
                
                // Calculate the center and radius for the circle
                let centerX = scaledBox.midX
                let centerY = scaledBox.midY
                let radius = min(scaledBox.width, scaledBox.height) / 2
                
                let circleRect = CGRect(
                    x: centerX - radius,
                    y: centerY - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                
                context.setStrokeColor(UIColor.white.cgColor)
                context.setLineWidth(5.0)
                context.strokeEllipse(in: circleRect) // Draw the circle
            }
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext() // Get the new image with rectangles
            UIGraphicsEndImageContext() // End the image context
            
            return newImage // Return the image with face rectangles
        }
    }
}

#Preview {
    ContentView()
}


/*
 
 RESOURCES

 on Optimization https://developer.apple.com/videos/play/wwdc2024/10163/

 ACKNOWLEDGMENTS
 
 Youtube Channel: ProgrammingWithAPurpose
 
*/
