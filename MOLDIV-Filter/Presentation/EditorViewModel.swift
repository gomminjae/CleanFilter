//
//  EditorViewModel.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//
//

import UIKit


extension UIImage {
    func resize(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        // ⛑️ CGImage가 없다면 CIImage → CGImage로 강제 생성
        if image.cgImage == nil, let ciImage = image.ciImage {
            let context = CIContext()
            if let cg = context.createCGImage(ciImage, from: ciImage.extent) {
                return UIImage(cgImage: cg)
            }
        }

        return image
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

                if let image = originalImage {
                    selectFilter(originalFilter)
                    generateThumbnails(baseImage: image)
                }
            } catch {
                print("필터 로딩 실패: \(error)")
            }
        }
    }

    func selectFilter(_ filter: FilterConfig) {
        selectedFilter = filter
        applySelectedFilter()
    }

    func setOriginalImage(_ image: UIImage) {
        originalImage = image

        if let original = filterList.first(where: { $0.id == "original" }) {
            selectFilter(original)
        } else {
            filteredImage = image
        }

        generateThumbnails(baseImage: image)
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
        Task {
            for filter in filterList {
                if filterThumbnails[filter.id] != nil { continue }

                if filter.id == "original" {
                    filterThumbnails[filter.id] = baseImage.resize(to: CGSize(width: 60, height: 60))
                    continue
                }

                do {
                    let resized = baseImage.resize(to: CGSize(width: 60, height: 60))
                    let result = try await applyFilterUseCase.execute(filter: filter, image: resized)
                    filterThumbnails[filter.id] = result
                    print("✅ 썸네일 생성 성공: \(filter.name)")
                } catch {
                    print("썸네일 생성 실패 (\(filter.name)): \(error)")
                }
            }
        }
    }
}
