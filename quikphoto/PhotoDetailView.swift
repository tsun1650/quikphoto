//
//  PhotoDetailView.swift
//  quikphoto
//
//  Created by Tony Sun on 2/16/25.
//


import SwiftUI
import Photos
import AVKit

struct PhotoDetailView: View {
    let asset: PHAsset
    let onDelete: (PHAsset) -> Void
    @State private var image: Image?
    @State private var player: AVPlayer?

    var body: some View {
        VStack {
            if asset.mediaType == .video {
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                if let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Created: \(asset.creationDate?.formatted() ?? "Unknown")")
                    Text("Size: \(getAssetSize())")
                }
                .padding()
                
                Spacer()
                
                Button(role: .destructive) {
                    onDelete(asset)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: [])
                .padding()
            }
        }
        .onAppear {
            if asset.mediaType == .video {
                loadVideo()
            } else {
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            if let image = result {
                self.image = Image(nsImage: image)
            }
        }
    }
    
    private func loadVideo() {
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestPlayerItem(forVideo: asset, options: options) { playerItem, error in
            if let error = error as? NSError {
                print("Error loading video: \(error.localizedDescription)")
                return
            }
            if let playerItem = playerItem {
                DispatchQueue.main.async {
                    self.player = AVPlayer(playerItem: playerItem)
                }
            }
        }
    }
    
    private func getAssetSize() -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first {
            let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
            let sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
            return ByteCountFormatter.string(fromByteCount: Int64(sizeOnDisk), countStyle: .file)
        }
        return "Unknown"
    }
}
