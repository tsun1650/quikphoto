import SwiftUI
import Photos

struct ContentView: View {
    @EnvironmentObject var photoLibrary: PhotoLibraryManager
    @State private var selectedAsset: PHAsset?
    @State private var showingSimilarPhotos = false
    @State private var similarGroups: [[PHAsset]] = []
    
    var body: some View {
        NavigationView {
            PhotoGridView(assets: photoLibrary.assets,
                         selectedAsset: $selectedAsset)
                .frame(minWidth: 300)
            
            if let asset = selectedAsset {
                PhotoDetailView(asset: asset, onDelete: deleteAsset)
                    .id(asset.localIdentifier) // Force view update when asset changes
            } else {
                Text("Select a photo or video to view")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            if !photoLibrary.isSizeCachingComplete {
                ToolbarItem(placement: .status) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Caching file sizes...")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSimilarPhotos) {
            SimilarPhotosView(groups: similarGroups, onDelete: deleteAsset)
        }
        .onAppear {
            photoLibrary.requestAuthorization()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sortByDate)) { _ in
            photoLibrary.sortByDate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sortBySize)) { _ in
            photoLibrary.sortBySize()
        }
        .onReceive(NotificationCenter.default.publisher(for: .findSimilar)) { _ in
            findSimilarPhotos()
        }
    }
    
    private func deleteAsset(_ asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, error in
            if success {
                DispatchQueue.main.async {
                    if selectedAsset == asset {
                        selectedAsset = nil
                    }
                    if let index = photoLibrary.assets.firstIndex(of: asset) {
                        photoLibrary.assets.remove(at: index)
                    }
                }
            }
        }
    }
    
    private func findSimilarPhotos() {
        Task {
            similarGroups = await photoLibrary.findSimilarPhotos()
            showingSimilarPhotos = !similarGroups.isEmpty
        }
    }
}
