//
//  ContentView.swift
//  FaceDetect
//
//  Created by Ricardo on 21/08/24.
//

import SwiftUI
import Vision

import SwiftUI
import Vision

struct ContentView: View {
    @ObservedObject private var viewModel = ViewModel()
    
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
            ScrollView(.horizontal) {
                HStack{
                    ForEach(viewModel.faceThumbnails, id: \.self) { thumbnail in
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .padding(4)
                    }
                    
                }
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
        @Published var faceThumbnails: [UIImage] = []

        
        func detectFaces(_ image: CGImage) async {
            let request = VNDetectFaceRectanglesRequest()
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([request])
                
                if let results = request.results, !results.isEmpty {
                    outputImage = addFaceRectsToImage(results: results, in: image)
                    generateFaceThumbnails(from: results, in: image)
                }
            } catch {
                print("Error performing face detection: \(error)")
            }
        }

        private func addFaceRectsToImage(results: [VNFaceObservation], in image: CGImage) -> UIImage? {
            let uiImage = UIImage(cgImage: image)
            let imageSize = CGSize(width: uiImage.size.width, height: uiImage.size.height)
            
            UIGraphicsBeginImageContext(imageSize)
            uiImage.draw(at: .zero)
            
            let context = UIGraphicsGetCurrentContext()!
            
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
                
                context.setStrokeColor(UIColor(.white.opacity(0.8)).cgColor)
                context.setLineWidth(5.0)
                context.strokeEllipse(in: circleRect) // Draw the circle
                
            }
            
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return newImage
        }

        private func generateFaceThumbnails(from results: [VNFaceObservation], in image: CGImage) {
            faceThumbnails.removeAll() // Clear any existing thumbnails
            
            let uiImage = UIImage(cgImage: image)
            let imageSize = CGSize(width: uiImage.size.width, height: uiImage.size.height)
            
            for face in results {
                let boundingBox = face.boundingBox
                let scaledBox = CGRect(
                    x: boundingBox.origin.x * imageSize.width,
                    y: (1 - boundingBox.origin.y - boundingBox.size.height) * imageSize.height,
                    width: boundingBox.size.width * imageSize.width,
                    height: boundingBox.size.height * imageSize.height
                )
                
                if let cgCroppedImage = uiImage.cgImage?.cropping(to: scaledBox) {
                    let thumbnail = UIImage(cgImage: cgCroppedImage)
                    faceThumbnails.append(thumbnail)
                }
            }
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
