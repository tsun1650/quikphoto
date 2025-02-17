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
    private let imageManager = PHImageManager.default()
    
    
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
        }
    }
    
    func sortByDate() {
        assets.sort { $0.creationDate ?? Date() > $1.creationDate ?? Date() }
    }
    
    func sortBySize() {
        // Create a dictionary to cache sizes
        var assetSizes: [PHAsset: Int64] = [:]
        
        let group = DispatchGroup()
        assets.forEach { asset in
            group.enter()
            
            let resources = PHAssetResource.assetResources(for: asset)
            var sizeOnDisk: Int64? = 0
            if let resource = resources.first {
                let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
                sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
                assetSizes[asset] = sizeOnDisk
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.assets.sort { first, second in
                return (assetSizes[first] ?? 0) > (assetSizes[second] ?? 0)
            }
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
