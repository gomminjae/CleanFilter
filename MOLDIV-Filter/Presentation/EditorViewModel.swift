//
//  EditorViewModel.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//
//

import UIKit
import PhotosUI
import Photos


extension UIImage {
    
    func toSRGBCompatible() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        
        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
        let rendered = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: self.size))
        }
        
        guard let cg = rendered.cgImage else {
            fatalError("SRGB 변환 실패")
        }
        return UIImage(cgImage: cg)
    }
    func normalized() -> UIImage {
        if self.imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return result
    }
    func resize(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        if let cg = image.cgImage {
            return UIImage(cgImage: cg)
        } else if let ci = image.ciImage {
            let context = CIContext()
            if let cg = context.createCGImage(ci, from: ci.extent) {
                return UIImage(cgImage: cg)
            }
        }
        
        fatalError("cgImage 생성 실패")
    }
}

@MainActor
protocol EditorViewBindable {
    var filterList: [FilterConfig] { get }
    var originalImage: UIImage? { get }
    var filteredImage: UIImage? { get }
    
    func loadFilters()
    func selectFilter(_ filter: FilterConfig)
    func setOriginalImage(_ image: UIImage)
}

@MainActor
class EditorViewModel: EditorViewBindable, ObservableObject {
    private let loadFilterUseCase: LoadFilterUseCase
    private let applyFilterUseCase: ApplyFilterUseCase
    
    @Published var filterList: [FilterConfig] = []
    @Published var originalImage: UIImage?
    @Published var filteredImage: UIImage?
    @Published var selectedFilter: FilterConfig?
    @Published var filterThumbnails: [String: UIImage] = [:]
    
    
    @Published var saveSuccess: Bool = false
    @Published var saveErrorMessage: String?
    
    private var pendingImage: UIImage?
    
    init(loadFilterUseCase: LoadFilterUseCase, applyFilterUseCase: ApplyFilterUseCase) {
        self.loadFilterUseCase = loadFilterUseCase
        self.applyFilterUseCase = applyFilterUseCase
    }
    
    func loadFilters() {
        Task {
            do {
                var filters = try await loadFilterUseCase.execute()
                let originalFilter = FilterConfig(id: "original", name: "원본", shader: "", thumbnail: "", parameters: [:])
                filters.insert(originalFilter, at: 0)
                self.filterList = filters
                
                if let image = pendingImage {
                    applyImage(image)
                    pendingImage = nil
                }
            } catch {
                print("❌ 필터 로딩 실패: \(error)")
            }
        }
    }

    
    func setOriginalImage(_ image: UIImage) {
        if filterList.isEmpty {
            pendingImage = image
        } else {
            applyImage(image)
        }
    }
    
    private func applyImage(_ image: UIImage) {
        self.originalImage = image
        self.filterThumbnails = [:]
        
        if let original = filterList.first(where: { $0.id == "original" }) {
            selectFilter(original)
        } else {
            filteredImage = image
        }
        
        generateThumbnails(baseImage: image)
    }
    
    func selectFilter(_ filter: FilterConfig) {
        selectedFilter = filter
        applySelectedFilter()
    }

    private func applySelectedFilter() {
        guard let filter = selectedFilter, let original = originalImage else { return }
        
        if filter.id == "original" {
            filteredImage = original
            return
        }
        
        Task {
            do {
                filteredImage = try await applyFilterUseCase.execute(filter: filter, image: original)
            } catch {
                print("필터 적용 실패: \(error)")
            }
        }
    }
    
    func generateThumbnails(baseImage: UIImage) {
        let normalized = baseImage.normalized().toSRGBCompatible()

        Task {
            for filter in filterList {
                if filterThumbnails[filter.id] != nil { continue }
                
                if filter.id == "original" {
                    filterThumbnails[filter.id] = normalized.resize(to: CGSize(width: 60, height: 60))
                    continue
                }
                
                do {
                    let resized = normalized.resize(to: CGSize(width: 40, height: 40))
                    let result = try await applyFilterUseCase.execute(filter: filter, image: resized)
                    filterThumbnails[filter.id] = result
                } catch {
                    print("썸네일 생성 실패 (\(filter.name)): \(error)")
                }
            }
        }
    }

    func resetFilter() {
        selectedFilter = nil
        filteredImage = originalImage
    }

    func confirmFilter() {
        print("필터 적용 완료: \(selectedFilter?.name ?? "없음")")
    }

    func saveToPhotoLibrary() {
        guard let image = filteredImage else { return }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            save(image)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    self.save(image)
                } else {
                    self.showPermissionAlert()
                }
            }
        case .denied, .restricted:
            showPermissionAlert()
        default:
            break
        }
    }

    private func save(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    print("저장 완료")
                    self.saveSuccess = true
                } else {
                    print("저장 실패: \(error?.localizedDescription ?? "알 수 없음")")
                    self.saveErrorMessage = error?.localizedDescription ?? "사진 저장에 실패했습니다."
                }
            }
        }
    }

    private func showPermissionAlert() {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return }

            let alert = UIAlertController(
                title: "사진 접근 권한 필요",
                message: "사진을 저장하려면 설정에서 사진 접근 권한을 허용해주세요.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })

            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            root.present(alert, animated: true)
        }
    }
}
