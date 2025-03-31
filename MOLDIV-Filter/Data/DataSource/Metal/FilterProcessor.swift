//
//  FilterProcessor.swift
//  MOLDIV-Filter
//
//  Created by 권민재 on 3/29/25.
//
import Metal
import MetalKit
import CoreImage
import UIKit


protocol ImageFiltering {
    func apply(filter: FilterConfig, to Image: UIImage) throws -> UIImage
}

enum MetalInitError: Error {
    case deviceUnvailable
    case commandQueueUnvailable
}
public enum MetalFilterError: Error, LocalizedError, Equatable {
    case invalidInputImage
    case textureLoadingFailed
    case shaderFunctionNotFound(name: String)
    case pipelineStateCreationFailed
    case outputTextureCreationFailed
    case encodingFailed
    case commandExecutionFailed
    case imageConversionFailed

    public var errorDescription: String? {
        switch self {
        case .invalidInputImage:
            return "입력 이미지가 유효하지 않습니다."
        case .textureLoadingFailed:
            return "이미지를 Metal 텍스처로 변환하는 데 실패했습니다."
        case .shaderFunctionNotFound(let name):
            return "필터 셰이더 '\(name)' 을(를) 찾을 수 없습니다."
        case .pipelineStateCreationFailed:
            return "셰이더 파이프라인 생성에 실패했습니다."
        case .outputTextureCreationFailed:
            return "출력 텍스처를 생성할 수 없습니다."
        case .encodingFailed:
            return "필터 커맨드 인코딩 중 문제가 발생했습니다."
        case .commandExecutionFailed:
            return "필터 처리 커맨드 실행에 실패했습니다."
        case .imageConversionFailed:
            return "결과 텍스처를 이미지로 변환하는 데 실패했습니다."
        }
    }
}
final class FilterProcessor: ImageFiltering {
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    init?(device: MTLDevice? = MTLCreateSystemDefaultDevice()) {
        guard let device = device,
              let queue = device.makeCommandQueue()
        else { return nil }
        
        self.device = device
        self.commandQueue = queue
    }
    func apply(filter: FilterConfig, to image: UIImage) throws -> UIImage {
        
        
        let normalized = image.normalized()
        
        guard let cgImage = normalized.cgImage ?? CIContext().createCGImage(CIImage(image: image)!, from: CIImage(image: image)!.extent) else {
            throw MetalFilterError.invalidInputImage
        }

        let loader = MTKTextureLoader(device: device)
        let inputTexture: MTLTexture
        do {
            inputTexture = try loader.newTexture(cgImage: cgImage, options: nil)
        } catch {
            throw MetalFilterError.textureLoadingFailed
        }

       
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: inputTexture.width,
            height: inputTexture.height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]

        guard let outputTexture = device.makeTexture(descriptor: descriptor) else {
            throw MetalFilterError.outputTextureCreationFailed
        }

       
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: filter.shader) else {
            throw MetalFilterError.shaderFunctionNotFound(name: filter.shader)
        }

        guard let pipeline = try? device.makeComputePipelineState(function: function) else {
            throw MetalFilterError.pipelineStateCreationFailed
        }

        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalFilterError.encodingFailed
        }

       
        var bufferData = MetalUniformBufferBuilder.build(from: filter.parameters, shader: filter.shader)
        print("Uniform:", bufferData)
        
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inputTexture, index: 0)
        encoder.setTexture(outputTexture, index: 1)
        encoder.setBytes(&bufferData, length: bufferData.count * MemoryLayout<Float>.stride, index: 0)


        let w = pipeline.threadExecutionWidth
        let h = max(1, pipeline.maxTotalThreadsPerThreadgroup / w)

        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)

        let threadgroupsPerGrid = MTLSize(
            width: (inputTexture.width + w - 1) / w,
            height: (inputTexture.height + h - 1) / h,
            depth: 1
        )

        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        guard var ciImage = CIImage(mtlTexture: outputTexture, options: nil) else {
            throw MetalFilterError.imageConversionFailed
        }
        
        let flippedTransform = CGAffineTransform(scaleX: 1, y: -1)
            .translatedBy(x: 0, y: -ciImage.extent.height)
        ciImage = ciImage.transformed(by: flippedTransform)
        
        let context = CIContext()
        guard let resultCG = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw MetalFilterError.imageConversionFailed
        }
        
        return UIImage(cgImage: resultCG)
    }

    
    
}
