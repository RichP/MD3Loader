//
//  GameViewController.swift
//  MD3Loader tvOS
//
//  Created by Richard Pickup on 18/02/2022.
//

import MetalKit

class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var timer: Float = 0
    
    let meshLoader = MD3Loader()
    var md3Model: MD3Mesh?
    var samplerState: MTLSamplerState?
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    let lighting = Lighting()
    lazy var camera: Camera = {
        let camera = ArcballCamera()
        camera.distance = 50
        camera.target = [0, 0, 0]
        camera.rotation.x = Float(-10).degreesToRadians
        return camera
    }()
    
    init(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
                fatalError("GPU not available")
            }
        
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        
        //md3Model = headloader.create(device: device, folder: "sarge")
        md3Model = meshLoader.create(device: device, folder: "Dragon")
        metalView.device = device
      
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        let vertexDescriptor = MD3Mesh.vertexDescriptor
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        samplerState = Renderer.buildSamplerState(device: device)
        super.init()
        fragmentUniforms.lightCount = UInt32(lighting.count)
        
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0,
                                             blue: 0.8, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.delegate = self
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState? {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat
        descriptor.mipFilter = .linear
        descriptor.maxAnisotropy = 8
        let samplerState = device.makeSamplerState(descriptor: descriptor)
        return samplerState
    }
    
    static func buildDepthStencilState(device: MTLDevice) -> MTLDepthStencilState? {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return device.makeDepthStencilState(descriptor: descriptor)
    }
    
    static func loadTexture(device: MTLDevice, imageName: String) throws -> MTLTexture? {
        guard imageName.count > 0 else { return nil }
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.topLeft ,
                                                                        .SRGB: false,
                                                                        .generateMipmaps: NSNumber(booleanLiteral: true)]
        
        let fileExtension = URL(fileURLWithPath: imageName).pathExtension.isEmpty ? "png" : nil
        
        guard let url = Bundle.main.url(forResource: imageName, withExtension: fileExtension) else {
            print("Failed to load \(imageName)")
            return try textureLoader.newTexture(name: imageName,
                                                scaleFactor: 1.0,
                                                bundle: Bundle.main,
                                                options: nil)
        }
        
        let texture = try textureLoader.newTexture(URL: url, options: textureLoaderOptions)
        
        print("loaded texture: \(url.lastPathComponent)")
        
        return texture
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.aspect = Float(view.bounds.width) / Float(view.bounds.height)
    }
    
    func draw(in view: MTKView) {
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder =
                commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                    return
                }
        if let depthStencilState = Renderer.buildDepthStencilState(device: Renderer.device) {
            renderEncoder.setDepthStencilState(depthStencilState)
        }
        
        let delta = 1.0 / Float(view.preferredFramesPerSecond)
        
        md3Model?.update(deltaTime: delta)
        
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        fragmentUniforms.cameraPosition = camera.position
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        var lights = lighting.lights
        renderEncoder.setFragmentBytes(&lights,
                                       length: MemoryLayout<Light>.stride * lights.count,
                                       index: Int(BufferIndexLights.rawValue))
        
        if let sampler = samplerState {
            renderEncoder.setFragmentSamplerState(sampler,
                                                  index: 0)
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        //renderEncoder.setTriangleFillMode(.lines)
        renderEncoder.setCullMode(.back)
        
        uniforms.modelMatrix = float4x4.identity()
        md3Model?.drawSkeleton(renderEncoder: renderEncoder, uniforms: uniforms)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

