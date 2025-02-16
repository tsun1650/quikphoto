//
//  PhotoDetailView.swift
//  quikphoto
//
//  Created by Tony Sun on 2/16/25.
//


import SwiftUI
import Photos

struct PhotoDetailView: View {
    let asset: PHAsset
    let onDelete: (PHAsset) -> Void
    @State private var image: Image?
    
    var body: some View {
        VStack {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            loadImage()
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
    
    private func getAssetSize() -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first {
            let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
            var sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
            return ByteCountFormatter.string(fromByteCount: Int64(sizeOnDisk), countStyle: .file)
        }
        return "Unknown"
    }
}
