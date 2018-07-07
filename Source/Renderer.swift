import Metal
import MetalKit
import simd

let alignedUniformsSize = (MemoryLayout<Uniforms>.size & ~0xFF) + 0x100

let maxBuffersInFlight = 3

enum RendererError: Error {
    case badVertexDescriptor
}

var gDevice:MTLDevice!
var mtlVertexDescriptor:MTLVertexDescriptor!
var uniforms: UnsafeMutablePointer<Uniforms>!

var constantData = ConstantData()
var constants: [MTLBuffer] = []
var constantsSize: Int = MemoryLayout<ConstantData>.stride
var constantsIndex: Int = 0
let kInFlightCommandBuffers = 3
var translationAmount = Float(-10)

var lightpos:float3 = float3()
var lAngle:Float = 0

var spinAngle:Float = 0
var spinAngleDelta:Float = 0.01

var pointCloud:PointCloud!

class Renderer: NSObject, MTKViewDelegate {
    let commandQueue: MTLCommandQueue
    var dynamicUniformBuffer: MTLBuffer
    var pipelineState: MTLRenderPipelineState
    var depthState: MTLDepthStencilState
    var colorMap: MTLTexture
    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)
    var uniformBufferOffset = 0
    var uniformBufferIndex = 0

    var projectionMatrix: matrix_float4x4 = matrix_float4x4()

    init?(metalKitView: MTKView) {
        gDevice = metalKitView.device!
        self.commandQueue = gDevice.makeCommandQueue()
        
        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        dynamicUniformBuffer = gDevice.makeBuffer(length:uniformBufferSize, options:[MTLResourceOptions.storageModeShared])//buffer
        
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents()).bindMemory(to:Uniforms.self, capacity:1)
        
        metalKitView.depthStencilPixelFormat = MTLPixelFormat.depth32Float_stencil8
        metalKitView.colorPixelFormat = MTLPixelFormat.bgra8Unorm_srgb
        metalKitView.sampleCount = 1
        
        mtlVertexDescriptor = Renderer.buildMetalVertexDescriptor()
        
        do {
            pipelineState = try Renderer.buildRenderPipelineWithDevice(device: gDevice,  metalKitView: metalKitView,  mtlVertexDescriptor: mtlVertexDescriptor)
        } catch {  print("Unable to compile render pipeline state.  Error info: \(error)"); return nil  }
        
        let depthStateDesciptor = MTLDepthStencilDescriptor()
        depthStateDesciptor.depthCompareFunction = MTLCompareFunction.less
        depthStateDesciptor.isDepthWriteEnabled = true
        depthState = gDevice.makeDepthStencilState(descriptor:depthStateDesciptor)

        pointCloud = PointCloud()
        
        do {
            colorMap = try Renderer.loadTexture(device: gDevice, textureName: "ColorMap")
        } catch {
            print("Unable to load texture. Error info: \(error)")
            return nil
        }
        
        constants = []
        for _ in 0..<kInFlightCommandBuffers {
            constants.append(gDevice.makeBuffer(length: constantsSize, options: []))
        }
        
        super.init()
    }
    
    class func buildMetalVertexDescriptor() -> MTLVertexDescriptor {
        let mtlVertexDescriptor = MTLVertexDescriptor()
 
        mtlVertexDescriptor.attributes[0].format = MTLVertexFormat.float3
        mtlVertexDescriptor.attributes[0].offset = 0
        mtlVertexDescriptor.attributes[0].bufferIndex = 0
        
        mtlVertexDescriptor.attributes[1].format = MTLVertexFormat.float2
        mtlVertexDescriptor.attributes[1].offset = 0
        mtlVertexDescriptor.attributes[1].bufferIndex = 1
        
        mtlVertexDescriptor.layouts[0].stride = 12
        mtlVertexDescriptor.layouts[0].stepRate = 1
        mtlVertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.perVertex
        
        mtlVertexDescriptor.layouts[1].stride = 8
        mtlVertexDescriptor.layouts[1].stepRate = 1
        mtlVertexDescriptor.layouts[1].stepFunction = MTLVertexStepFunction.perVertex

        return mtlVertexDescriptor
    }
    
    class func buildRenderPipelineWithDevice(device: MTLDevice,
                                             metalKitView: MTKView,
                                             mtlVertexDescriptor: MTLVertexDescriptor) throws -> MTLRenderPipelineState {
        let library = device.newDefaultLibrary()
        
        let vFunction = library?.makeFunction(name: "texturedVertexShader")
        let fFunction = library?.makeFunction(name: "texturedFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.sampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vFunction
        pipelineDescriptor.fragmentFunction = fFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    class func loadTexture(device: MTLDevice, textureName: String) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: device)
        return try textureLoader.newTexture(withName: textureName, scaleFactor: 1.0, bundle: nil,  options: nil)
    }
    
    private func updateDynamicBufferState() {
        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight
        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to:Uniforms.self, capacity:1)
    }
    
    func draw(in view: MTKView) {
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let semaphore = inFlightSemaphore
        commandBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in semaphore.signal() }
        
        self.updateDynamicBufferState()
        
        let renderPassDescriptor = view.currentRenderPassDescriptor
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor!)
        renderEncoder.setCullMode(.back)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthState)
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, at: 2)
        renderEncoder.setFragmentBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, at: 2)
        renderEncoder.setFragmentTexture(colorMap, at:0)

        // -----------------------------
        let constant_buffer = constants[constantsIndex].contents().assumingMemoryBound(to: ConstantData.self)
        constant_buffer[0].mvp =
            projectionMatrix
            * matrix4x4_translation(0,0,translationAmount)
            * matrix4x4_rotation(spinAngle,float3(0,1,0))
        
        spinAngle += spinAngleDelta
        
        lightpos.x = sinf(lAngle) * 5
        lightpos.y = 5
        lightpos.z = cosf(lAngle) * 5
        lAngle += 0.01
        constant_buffer[0].light = normalize(lightpos)
        
        renderEncoder.setVertexBuffer(constants[constantsIndex], offset:0, at: 1)

        // ----------------------------------------------
        pointCloud.render(renderEncoder)
        // ----------------------------------------------

        renderEncoder.endEncoding()
        
        if let drawable = view.currentDrawable { commandBuffer.present(drawable)  }
        commandBuffer.commit()
        constantsIndex = (constantsIndex + 1) % kInFlightCommandBuffers
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = matrix_perspective_right_hand(fovyRadians: radians_from_degrees(65), aspectRatio:aspect, nearZ: 0.1, farZ: 100.0)
    }
}
