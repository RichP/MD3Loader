//
//  MD3Loader.swift
//  MD3Loader
//
//  Created by Richard Pickup on 18/02/2022.
//

import Foundation
import ModelIO
import MetalKit

struct MD3Header {
    let ID: String
    let version: Int32
    let Filename: String
    let numBoneFrames: Int32
    let numTags: Int32
    let numMeshes: Int32
    let numMaxSkins: Int32
    let frameOffset: Int32
    let tagOffset: Int32
    let surfacesOffset: Int32
    let FileSize: Int32
    
    init(data: Data) {
        var byteData = data
        let chars = byteData.subData(size: MemoryLayout<CChar>.size, count: 4)
        self.ID = String(bytes: chars, encoding: .utf8) ?? ""
        let version:[Int32] = byteData.subData(size: MemoryLayout<Int32>.size, count: 1).elements()
        self.version = version[0]
        let fileChars: [CChar] = byteData.subData(size: MemoryLayout<CChar>.size, count: 68).elements()
        let cString = String(cString: fileChars)
        self.Filename = cString
        let ints:[Int32] = byteData.subData(size: MemoryLayout<Int32>.size, count: 8).elements()
        self.numBoneFrames = ints[0]
        self.numTags = ints[1]
        self.numMeshes = ints[2]
        self.numMaxSkins = ints[3]
        self.frameOffset = ints[4]
        self.tagOffset = ints[5]
        self.surfacesOffset = ints[6]
        self.FileSize = ints[7]
        
    }
}

struct BoneFrame {
    let mins: (Float, Float, Float)
    let max: (Float, Float, Float)
    let position: (Float, Float, Float)
    let scale: Float
    let creator: (CChar, CChar, CChar, CChar,CChar, CChar, CChar, CChar,CChar, CChar, CChar, CChar,CChar, CChar, CChar, CChar)
}

struct Tag {
    let name: String
    let position: (Float, Float, Float)
    let rotation: ((Float, Float, Float),
                   (Float, Float, Float),
                   (Float, Float, Float))
}

struct MeshHeader {
    let ID: String
    let name: String
    let flags: Int32
    let numMeshFrames: Int32
    let numSkins: Int32
    let numVertexes: Int32
    let numTriangles: Int32
    let trianglesOffset: Int32
    let skinsOffset: Int32
    let texVectorOffset: Int32
    let vertexOffset: Int32
    let meshSize: Int32
    init?(file: FileHandle, offset: UInt64) {
        try? file.seek(toOffset: UInt64(offset))
        
        guard let idChars = try? file.read(upToCount: 4),
              let nameChars: [CChar] = try? file.read(upToCount: 64)?.elements(),
              let ints: [Int32] = try? file.read(upToCount: MemoryLayout<Int32>.size * 10)?.elements() else {
                  return nil
              }
        let st: String = String(bytes: idChars, encoding: .utf8)!
        self.ID = st
        self.name = String(cString: nameChars)
        self.flags = ints[0]
        self.numMeshFrames = ints[1]
        self.numSkins = ints[2]
        self.numVertexes = ints[3]
        self.numTriangles = ints[4]
        self.trianglesOffset = ints[5]
        self.skinsOffset = ints[6]
        self.texVectorOffset = ints[7]
        self.vertexOffset = ints[8]
        self.meshSize = ints[9]
    }
}

struct Skin {
    let name: String
    let index: Int32
}

struct Vertex {
    let vertex: (Int16, Int16, Int16)
    let normal: (UInt8, UInt8)
}

struct Triangle {
    let vertex: (Int32, Int32, Int32)
}

struct TexCoord {
    let coord: (Float, Float)
}

struct Mesh {
    let header: MeshHeader
    let skin: [Skin]
    let triangle: [Triangle]
    let texCoord: [TexCoord]
    let vertex: [Vertex]
    var textureName: String?
    var mtkMesh: MTKMesh?
    var texture: MTLTexture?
}


class MD3Mesh {
    var header: MD3Header!
    var bones: [BoneFrame] = []
    var tags: [Tag] = []
    var meshes: [Mesh] = []
    
    var currentFrame = 0
    var nextFrame = 0
    
    var animation = 0
    
    var delta: Float = 0.0
    
    var currentTime: Float = 0.0
    var oldTime: Float = 0.0
    
    var animations: [AnimationInfo] = []
    
    var links: [MD3Mesh?] = [MD3Mesh?](repeating: nil, count: 10)
    
    init(header: MD3Header, bones: [BoneFrame], tags: [Tag], meshes: [Mesh]) {
        self.header = header
        self.bones = bones
        self.tags = tags
        self.meshes = meshes
    }
    
    func attachModel(model: MD3Mesh?, link: String) {
        guard let model = model else { return }
        links = [MD3Mesh?](repeating: nil, count: 10)
        for i in 0..<header.numTags {
            let tag = tags[Int(i)]
            if tag.name == link {
                links[Int(i)] = model
                return
            }
        }
    }
    
    func setAnimation(anim: Animation) {
        guard let index = animations.firstIndex(where: {$0.name == anim.name}) else { return }
        
        let newAnim = animations[index]
        
        animation = index
        currentFrame = newAnim.startFrame
        
        nextFrame = newAnim.numFrames > 0 ? newAnim.startFrame + 1 : newAnim.startFrame
    }
    
    func update(deltaTime: Float) {
        currentTime += deltaTime
        if animations.isEmpty {
            return
        }
        let currentAnimation = animations[animation]
        
        if currentFrame < currentAnimation.startFrame
        {
            currentFrame = currentAnimation.startFrame
            nextFrame = currentAnimation.numFrames > 0 ? currentAnimation.startFrame + 1 : currentAnimation.startFrame
        }
        
        let animSpeed = Float(currentAnimation.fps)
        let elapsedTime = currentTime - oldTime
        var t = elapsedTime / (1.0 / animSpeed)
        
        if elapsedTime > (1.0 / animSpeed) {
            
            currentFrame = nextFrame
            let endFrame = currentAnimation.startFrame + currentAnimation.numFrames
            nextFrame += 1
            if nextFrame > endFrame {
                nextFrame = currentAnimation.startFrame
            }
            
            oldTime = currentTime
            t = 0
        }
        
        delta = t
        
        buildMeshes(device: Renderer.device)
        
        for i in 0..<header.numTags {
            guard let link = links [Int(i)] else {
                // print("No Links")
                continue
            }
            link.update(deltaTime: deltaTime)
        }
        
    }
    
    func drawSkeleton(renderEncoder: MTLRenderCommandEncoder?, uniforms: Uniforms){
        
        var newUniforms = uniforms
        newUniforms.normalMatrix = uniforms.modelMatrix.upperLeft
        renderEncoder?.setVertexBytes(&newUniforms,
                                      length: MemoryLayout<Uniforms>.stride,
                                      index: Int(BufferIndexUniforms.rawValue))
        
        
        
        
        for mesh in meshes {
            if let mtkMesh = mesh.mtkMesh {
                if let tex = mesh.texture {
                    renderEncoder?.setFragmentTexture(tex,
                                                     index: Int(BaseColorTexture.rawValue))
                }
                renderEncoder?.setVertexBuffer(mtkMesh.vertexBuffers[0].buffer, offset: 0, index: 0)
                for mtkSubmesh in mtkMesh.submeshes {
                    
                    renderEncoder?.pushDebugGroup("Starting Render \(mtkSubmesh.name)")
                    renderEncoder?.drawIndexedPrimitives(type: .triangle,
                                                         indexCount: mtkSubmesh.indexCount,
                                                         indexType: mtkSubmesh.indexType,
                                                         indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                                         indexBufferOffset: mtkSubmesh.indexBuffer.offset)
                    renderEncoder?.popDebugGroup()
                }
            }
        }
        
        for i in 0..<header.numTags {
            guard let link = links [Int(i)] else {
                // print("No Links")
                continue
            }
            let index = Int(i)
            
            let rotation = tags[currentFrame * Int(header.numTags) + index].rotation
            let position = tags[currentFrame * Int(header.numTags) + index].position
            
            let nextRotation = tags[nextFrame * Int(header.numTags) + index].rotation
            let nextPosition = tags[currentFrame * Int(header.numTags) + index].position
            
            
            let vx = position.0 + delta * (nextPosition.0 - position.0)
            let vy = position.1 + delta * (nextPosition.1 - position.1)
            let vz = position.2 + delta * (nextPosition.2 - position.2)
            
            let matA = float3x3(
                [rotation.0.0, rotation.0.1, rotation.0.2],
                [rotation.1.0, rotation.1.1, rotation.1.2],
                [rotation.2.0, rotation.2.1, rotation.2.2])
            
            let matB = float3x3(
                [nextRotation.0.0, nextRotation.0.1, nextRotation.0.2],
                [nextRotation.1.0, nextRotation.1.1, nextRotation.1.2],
                [nextRotation.2.0, nextRotation.2.1, nextRotation.2.2])
            
            let q1 = simd_quatf(matA)
            let q2 = simd_quatf(matB)
            let slerp =  simd_slerp(q1, q2, delta)
            
            var newMatrix = float4x4(slerp)
            newMatrix.columns.3 = [vx, vy ,vz, 1]
            
            let mat = uniforms.modelMatrix * newMatrix
            
            newUniforms.modelMatrix = mat
            link.drawSkeleton(renderEncoder: renderEncoder, uniforms: newUniforms)
        }
    }
    
    func buildMeshes(device: MTLDevice) {
        for i in 0..<header.numMeshes {
            buildMesh(number: Int(i), device: device)
        }
    }
    func buildMesh(number: Int, device: MTLDevice) {
        let allocator = MTKMeshBufferAllocator(device: device)
        
        let mesh = meshes[number]
        let numTris = mesh.header.numTriangles
        
        
        let numVerts = mesh.header.numVertexes
        
        let frame = Int(numVerts) * currentFrame
        let frame2 = Int(numVerts) * nextFrame
        var meshVerts: [float3] = []
        for i in 0..<numVerts {
            let index = Int(i) + frame
            let index2 = Int(i) + frame2
            
            let v0: Float = Float(mesh.vertex[index].vertex.0) / 64.0
            let v1: Float = Float(mesh.vertex[index].vertex.1) / 64.0
            let v2: Float = Float(mesh.vertex[index].vertex.2) / 64.0
            
            let nv0: Float = Float(mesh.vertex[index2].vertex.0) / 64.0
            let nv1: Float = Float(mesh.vertex[index2].vertex.1) / 64.0
            let nv2: Float = Float(mesh.vertex[index2].vertex.2) / 64.0
            
            
            let pA0 = v0 + delta * (nv0 - v0)
            let pA1 = v1 + delta * (nv1 - v1)
            let pA2 = v2 + delta * (nv2 - v2)
            
            let u = mesh.texCoord[Int(i)].coord.0
            let v = mesh.texCoord[Int(i)].coord.1
            
            meshVerts.append(float3(pA0, pA1,pA2))
            
            meshVerts.append(float3(0, 0, 0))
            meshVerts.append(float3(u, v, 0))
        }
        
        var indices: [Int32] = []
        for i in 0..<numTris {
            let index = Int(i)
            indices.append(mesh.triangle[index].vertex.0)
            indices.append(mesh.triangle[index].vertex.2)
            indices.append(mesh.triangle[index].vertex.1)
        }
        
        let packedFloat3Size = MemoryLayout<float3>.stride
        
        let mdlMeshVertexBuffer = allocator.newBuffer(packedFloat3Size * meshVerts.count, type: .vertex)
        let vertexMap = mdlMeshVertexBuffer.map()
        vertexMap.bytes.assumingMemoryBound(to: float3.self).assign(from: meshVerts, count: meshVerts.count)
        
        let indexBuffer = allocator.newBuffer(MemoryLayout<Int32>.stride * indices.count, type: .index)
        let indexMap = indexBuffer.map()
        indexMap.bytes.assumingMemoryBound(to: Int32.self).assign(from: indices, count: indices.count)
        
        let sub = MDLSubmesh(name: mesh.header.name,
                             indexBuffer: indexBuffer,
                             indexCount: indices.count,
                             indexType: .uint32,
                             geometryType: .triangles,
                             material: nil)
        
        
        let mdlMesh = MDLMesh(vertexBuffer: mdlMeshVertexBuffer,
                              vertexCount: meshVerts.count / 3,
                              descriptor: MD3Mesh.vertexDescriptor,
                              submeshes: [sub])
        
        
        mdlMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal,
                           creaseThreshold: 0.5)
        
        do {
            let mtkMesh = try MTKMesh(mesh: mdlMesh, device: device)
            meshes[number].mtkMesh = mtkMesh
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    static var vertexDescriptor: MDLVertexDescriptor = {
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0
        
        let packedFloat3Size = MemoryLayout<float3>.stride
        vertexDescriptor.attributes[Int(Position.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                                                 format: .float3,
                                                                                 offset: offset,
                                                                                 bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += packedFloat3Size
        vertexDescriptor.attributes[Int(Normal.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                                               format: .float3,
                                                                               offset: offset,
                                                                               bufferIndex: Int(BufferIndexVertices.rawValue))
        
        offset += packedFloat3Size
        
        vertexDescriptor.attributes[Int(UV.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                                           format: .float3,
                                                                           offset: offset,
                                                                           bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += packedFloat3Size
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        return vertexDescriptor
    }()
    
    
}


class MD3Loader {
    var lower: MD3Mesh?
    var upper: MD3Mesh?
    var head: MD3Mesh?
    
    let md3Indentifier = "IDP3"
    let md3Version = 15
    
    func create(device: MTLDevice, folder: String) -> MD3Mesh? {
        
        lower = loadModel(filename: "\(folder)/lower")
        upper = loadModel(filename: "\(folder)/upper")
        head = loadModel(filename: "\(folder)/head")
        
        if let anims = loadAnimation(path: "\(folder)/animation") {
            for anim in anims {
                var assignedAnim = anim
                if assignedAnim.numFrames > 0 {
                    assignedAnim.numFrames = anim.numFrames - 1
                }
                
                if anim.name.contains("BOTH") {
                    lower?.animations.append(assignedAnim)
                    upper?.animations.append(assignedAnim)
                }
                
                if anim.name.contains("TORSO") {
                    upper?.animations.append(assignedAnim)
                }
                
                if anim.name.contains("LEGS") {
                    let legsStart = anims[Animation.legsWalkCR.rawValue].startFrame
                    let torsoStart = anims[Animation.torsoGesture.rawValue].startFrame
                    
                    let offset = legsStart - torsoStart
                    
                    assignedAnim.startFrame = anim.startFrame - offset
                    
                    lower?.animations.append(assignedAnim)
                }
            }
        }
        
        loadSkin(folder:"\(folder)", path: "\(folder)/lower_default", mesh: lower)
        loadSkin(folder:"\(folder)", path: "\(folder)/upper_default", mesh: upper)
        loadSkin(folder:"\(folder)", path: "\(folder)/head_default", mesh: head)
        
        
        lower?.attachModel(model: upper, link: "tag_torso")
        upper?.attachModel(model: head, link: "tag_head")
        
        lower?.setAnimation(anim: .legsIdle)
        upper?.setAnimation(anim: .torsoGesture)
        
        lower?.buildMeshes(device: device)
        upper?.buildMeshes(device: device)
        head?.buildMeshes(device: device)
        
        return lower
    }
    
    func loadSkin(folder: String, path: String, mesh: MD3Mesh?) {
        guard let filePath = Bundle.main.url(forResource: path, withExtension: "skin") else {
            return
        }
        
        do {
            let data = try String(contentsOf: filePath)
            let lines = data.components(separatedBy: .newlines)
            for line in lines {
                let tokens: [String] = line.components(separatedBy: ",")
                let meshName = tokens.first
                let texture = tokens.last?.components(separatedBy: "/").last
                
                guard let len = texture?.count, len > 0 else { continue }
                
                for (index, _) in (mesh?.meshes ?? []).enumerated() {
                    if mesh?.meshes[index].header.name == meshName {
                        mesh?.meshes[index].textureName = texture ?? ""
                        let texturePath = folder + "/" + (texture ?? "")
                        mesh?.meshes[index].texture = try? Renderer.loadTexture(device: Renderer.device, imageName: texturePath)
                    }
                }
            }
        } catch {
            return
        }
    }
    
    func loadAnimation(path: String) -> [AnimationInfo]? {
        guard let filePath = Bundle.main.url(forResource: path, withExtension: "cfg") else {
            return nil
        }
        var animations: [AnimationInfo] = []
        do {
            let data = try String(contentsOf: filePath)
            let lines = data.components(separatedBy: .newlines)
            for string in lines {
                let tokens: [String] = string.components(separatedBy: .whitespaces)
                guard tokens.count >= 6,
                      let startFrame = Int(tokens[0]),
                      let endFrame = Int(tokens[1]),
                      let loopingFrames = Int(tokens[2]),
                      let fps = Int(tokens[3]) else {
                          continue
                      }
                animations.append(AnimationInfo(name: tokens[6],
                                                startFrame: startFrame,
                                                numFrames: endFrame,
                                                loopingFrames: loopingFrames,
                                                fps: fps))
            }
        } catch {
            return nil
        }
        return animations
    }
    
    func loadModel(filename: String) -> MD3Mesh? {
        
        guard let filePath = Bundle.main.url(forResource: filename, withExtension: "md3") else {
            return nil
        }
        
        guard let file = try? FileHandle(forReadingFrom: filePath) else {
            print("File open failed")
            return nil
        }
        
        let header = MD3Header(data: file.availableData)
        
        if header.ID != md3Indentifier || header.version != md3Version {
            file.closeFile()
            return nil
        }
        
        try? file.seek(toOffset: UInt64(header.frameOffset))
        
        let boneSize = MemoryLayout<BoneFrame>.size
        
        guard let bonesDat = try? file.read(upToCount: boneSize * Int(header.numBoneFrames)) else {
            file.closeFile()
            return nil
        }
        let bones: [BoneFrame] = bonesDat.elements()
        
        let floatSize = MemoryLayout<Float>.size
        
        try? file.seek(toOffset: UInt64(header.tagOffset))
        var tags: [Tag] = []
        for _ in 0..<(header.numTags * header.numBoneFrames) {
            if let chars: [CChar] = try? file.read(upToCount: 64)?.elements(),
               let pos: [Float] = try? file.read(upToCount: floatSize * 3)?.elements(),
               let rot: [Float]  = try? file.read(upToCount: floatSize * 9)?.elements() {
                
                let tag = Tag(name: String(cString: chars),
                              position: (pos[0], pos[1], pos[2]),
                              rotation: ((rot[0], rot[1], rot[2]),
                                         (rot[3], rot[4], rot[5]),
                                         (rot[6], rot[7], rot[8])))
                
                tags.append(tag)
            }
        }
        
        var offset = header.surfacesOffset
        var meshes: [Mesh] = []
        for _ in 0..<header.numMeshes {
            
            if let meshHeader = MeshHeader(file: file, offset: UInt64(offset)) {
                try? file.seek(toOffset: UInt64(offset + meshHeader.trianglesOffset))
                
                let tris: [Triangle] = file.readElements(count: Int(meshHeader.numTriangles)) ?? []
                
                try? file.seek(toOffset: UInt64(offset + meshHeader.skinsOffset))
                
                var skins: [Skin] = []
                for _ in 0..<meshHeader.numSkins {
                    
                    if var chars: [CChar] = try? file.read(upToCount: 64)?.elements(),
                       let indx: [Int32] = try? file.read(upToCount: MemoryLayout<Int32>.size)?.elements() {
                        chars.removeFirst()
                        let skin = Skin(name: String(cString: chars),
                                        index: indx.first ?? 0)
                        skins.append(skin)
                    }
                    
                }
                try? file.seek(toOffset: UInt64(offset + meshHeader.texVectorOffset))
                
                let tex: [TexCoord] = file.readElements(count: Int(meshHeader.numVertexes)) ?? []
                
                try? file.seek(toOffset: UInt64(offset + meshHeader.vertexOffset))
                
                let verts: [Vertex] = file.readElements(count: Int(meshHeader.numVertexes * meshHeader.numMeshFrames)) ?? []
                
                let mesh = Mesh(header: meshHeader,
                                skin: skins,
                                triangle: tris,
                                texCoord: tex,
                                vertex: verts)
                meshes.append(mesh)
                
                offset += meshHeader.meshSize
            }
            
        }
        
        file.closeFile()
        let md3Mesh = MD3Mesh(header: header,
                              bones: bones,
                              tags: tags,
                              meshes: meshes)
        return md3Mesh
    }
}

extension FileHandle {
    func readElements <T> (count: Int) -> [T]? {
        let size = MemoryLayout<T>.size
        if let data = try? read(upToCount: size * count) {
            let elements: [T] = data.elements()
            return elements
        }
        return nil
    }
}

extension Data {
    func elements <T> () -> [T] {
        return withUnsafeBytes { dataBytes in
            
            let buffer: UnsafePointer<T> = dataBytes.baseAddress!.assumingMemoryBound(to: T.self)
            return Array( UnsafeBufferPointer<T>(start: buffer, count: count / MemoryLayout<T>.size) )
        }
    }
    
    mutating func subData(size: Int, count: Int) -> Data {
        let range = 0..<(size * count)
        let data = subdata(in: range)
        removeSubrange(range)
        return data
    }
}
