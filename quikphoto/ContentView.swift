import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var photoLibrary = PhotoLibraryManager()
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
            } else {
                Text("Select a photo or video to view")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    if let index = photoLibrary.assets.firstIndex(of: asset) {
                        photoLibrary.assets.remove(at: index)
                    }
                    selectedAsset = nil
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
