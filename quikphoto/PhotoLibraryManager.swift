//
//  PhotoLibraryManager.swift
//  quikphoto
//
//  Created by Tony Sun on 2/16/25.
//


import Photos
import CoreImage
import Vision
import AVKit

class PhotoLibraryManager: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var isSizeCachingComplete: Bool = false
    private let imageManager = PHImageManager.default()
    private var assetSizes: [String: Int64] = [:] 

    
    func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized {
                self.fetchAssets()
            }
        }
    }
    
    private func fetchAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        DispatchQueue.main.async {
            self.assets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))
            self.precalculateAssetSizes()
        }
    }
    
//    private func precalculateAssetSizes() {
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            guard let self = self else { return }
//            for asset in self.assets {
//                let resources = PHAssetResource.assetResources(for: asset)
//                if let resource = resources.first {
//                    if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
//                        let sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64))
//                        DispatchQueue.main.async {
//                            self.assetSizes[asset.localIdentifier] = sizeOnDisk
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
    private func precalculateAssetSizes() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isSizeCachingComplete = false
            }

            for asset in self.assets {
                let resources = PHAssetResource.assetResources(for: asset)
                if let resource = resources.first {
                    var sizeOnDisk: Int64 = 0

                
                    // Fallback to value(forKey:) method
                    if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                        sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64))
                    }
                

                    if sizeOnDisk > 0 {
                        DispatchQueue.main.async {
                            self.assetSizes[asset.localIdentifier] = sizeOnDisk
//                            print("Cached size for asset \(asset.localIdentifier): \(sizeOnDisk)")
                        }
                    } else {
//                        print("Failed to get size for asset \(asset.localIdentifier)")
                    }
                }
            }

            // Log total number of cached sizes
            DispatchQueue.main.async {
                self.isSizeCachingComplete = true
            }
        }
        
        DispatchQueue.global(qos: .background).async(execute: workItem)
    }
    
    func sortByDate() {
        assets.sort { $0.creationDate ?? Date() > $1.creationDate ?? Date() }
    }
    
    func sortBySize() {
    assets.sort { first, second in
                let firstSize = assetSizes[first.localIdentifier] ?? 0
                let secondSize = assetSizes[second.localIdentifier] ?? 0
                return firstSize > secondSize
            }
    }
    
    func findSimilarPhotos() async -> [[PHAsset]] {
        var similarGroups: [[PHAsset]] = []
        var processedAssets: Set<String> = []
        
        let requestHandler = VNSequenceRequestHandler()
        
        for asset in assets {
            if processedAssets.contains(asset.localIdentifier) { continue }
            
            var currentGroup: [PHAsset] = [asset]
            let assetFingerprint = try? await getAssetFingerprint(for: asset)
            
            for otherAsset in assets where otherAsset != asset {
                if processedAssets.contains(otherAsset.localIdentifier) { continue }
                
                let otherFingerprint = try? await getAssetFingerprint(for: otherAsset)
                
                if let fingerprint1 = assetFingerprint,
                   let fingerprint2 = otherFingerprint,
                   areImagesSimilar(fingerprint1, fingerprint2) {
                    currentGroup.append(otherAsset)
                    processedAssets.insert(otherAsset.localIdentifier)
                }
            }
            
            if currentGroup.count > 1 {
                similarGroups.append(currentGroup)
            }
            processedAssets.insert(asset.localIdentifier)
        }
        
        return similarGroups
    }
    
    private func getAssetFingerprint(for asset: PHAsset) async throws -> VNFeaturePrintObservation {
          return try await withCheckedThrowingContinuation { continuation in
              let options = PHImageRequestOptions()
              options.deliveryMode = .highQualityFormat
              options.isNetworkAccessAllowed = true
              options.isSynchronous = true

              imageManager.requestImage(
                  for: asset,
                  targetSize: CGSize(width: 224, height: 224),
                  contentMode: .aspectFit,
                  options: options
              ) { image, _ in
                  guard let cgImage = image?.cgImage else {
                      continuation.resume(throwing: NSError(domain: "PhotoManager", code: -1))
                      return
                  }

                  do {
                      let request = VNGenerateImageFeaturePrintRequest()
                      try VNImageRequestHandler(cgImage: cgImage as! CGImage).perform([request])
                      if let result = request.results?.first as? VNFeaturePrintObservation {
                          continuation.resume(returning: result)
                      } else {
                          continuation.resume(throwing: NSError(domain: "PhotoManager", code: -2))
                      }
                  } catch {
                      continuation.resume(throwing: error)
                  }
              }
          }
   }

    private func areImagesSimilar(_ print1: VNFeaturePrintObservation, _ print2: VNFeaturePrintObservation) -> Bool {
        var d = Float(1)
        try? print1.computeDistance(&d, to: print2)
        return d < 0.5 // Adjust threshold as needed
    }
    
    func sortByVideos() {
        assets.sort { first, second in
            if first.mediaType == .video && second.mediaType != .video {
                return true
            } else if first.mediaType != .video && second.mediaType == .video {
                return false
            }
            return first.creationDate ?? Date() > second.creationDate ?? Date()
        }
    }
    
    func isVideo(_ asset: PHAsset) -> Bool {
        return asset.mediaType == .video
    }

    func getDuration(_ asset: PHAsset) -> String {
        guard asset.mediaType == .video else { return "" }
        let seconds = Int(asset.duration)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
}
