//
//  PhotoGridView.swift
//  quikphoto
//
//  Created by Tony Sun on 2/16/25.
//


import SwiftUI
import Photos

struct PhotoGridView: View {
    let assets: [PHAsset]
    @Binding var selectedAsset: PHAsset?
    
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    PhotoThumbnailView(asset: asset, isSelected: asset == selectedAsset)
                        .onTapGesture {
                            selectedAsset = asset
                        }
                }
            }
            .padding()
        }
    }
}

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let isSelected: Bool
    @State private var image: Image?
    
    var body: some View {
        ZStack {
            Group {
                if let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray
                }
            }
            .frame(width: 150, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            
            if asset.mediaType == .video {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.white)
                            .padding(.leading, 5)
                        Text(getDuration(asset))
                            .foregroundColor(.white)
                            .padding(.trailing, 5)
                        Spacer()
                    }
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.black.opacity(0.7))
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let image = result {
                self.image = Image(nsImage: image)
            }
        }
    }
    
    private func getDuration(_ asset: PHAsset) -> String {
        guard asset.mediaType == .video else { return "" }
        let seconds = Int(asset.duration)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
