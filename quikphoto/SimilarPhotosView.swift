//
//  SimilarPhotosView.swift
//  quikphoto
//
//  Created by Tony Sun on 2/16/25.
//


import SwiftUI
import Photos

struct SimilarPhotosView: View {
    let groups: [[PHAsset]]
    let onDelete: (PHAsset) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(groups.enumerated()), id: \.offset) { index, group in
                    Section("Group \(index + 1)") {
                        ScrollView(.horizontal) {
                            HStack(spacing: 20) {
                                ForEach(group, id: \.localIdentifier) { asset in
                                    VStack {
                                        PhotoThumbnailView(asset: asset, isSelected: false)
                                            .frame(width: 200, height: 200)
                                        
                                        Button(role: .destructive) {
                                            onDelete(asset)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Similar Photos")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}
