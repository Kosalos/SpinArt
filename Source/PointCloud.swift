import Metal
import MetalKit
import simd

class PointCloud {
    var pBuffer: MTLBuffer?
    var pData = Array<TVertex>()
    var iBuffer: MTLBuffer?
    var iData = Array<UInt16>()     // indices
    
    func reset() {
        pData.removeAll()
        iData.removeAll()
    }
    
    //   ------------------------------------------------------
    var oldCount:Int =  0
    
    func addCube(_ pt:CGPoint) {
        let indices:[UInt16] = [
            0,1,3,    // front
            1,2,3,
            5,4,6,    // back
            4,7,6,
            4,0,7,    // left
            0,3,7,
            1,5,2,    // right
            5,6,2,
            4,5,0,    // top
            5,1,0,
            3,2,7,    // bottom
            2,6,7 ]

        var x = (Float(pt.x) - bounds.x/2) * 0.01
        let y = -(Float(pt.y) - bounds.y/2) * 0.01
        var z = Float(0)
        let ss = sinf(spinAngle)
        let cc = cosf(spinAngle)
        let qt = x
        x = x * cc - z * ss
        z = qt * ss + z * cc

        let sz:Float = 0.01 + Float(vector.dy) / 5.0
        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        drawColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let color = simd_float4(Float(r),Float(g),Float(b),Float(1))
        
        let pos:simd_float3 = simd_float3(x,y,z)
        
        func spin(_ vv:simd_float3) -> simd_float3 {
            var ans = vv
            ans.x = ans.x * cc - ans.z * ss
            ans.z = vv.x * ss + ans.z * cc
            return ans
        }
        
        let p1 = spin(simd_float3(-sz,-sz,-sz)) + pos
        let p2 = spin(simd_float3(+sz,-sz,-sz)) + pos
        let p3 = spin(simd_float3(+sz,+sz,-sz)) + pos
        let p4 = spin(simd_float3(-sz,+sz,-sz)) + pos
        let p5 = spin(simd_float3(-sz,-sz,+sz)) + pos
        let p6 = spin(simd_float3(+sz,-sz,+sz)) + pos
        let p7 = spin(simd_float3(+sz,+sz,+sz)) + pos
        let p8 = spin(simd_float3(-sz,+sz,+sz)) + pos

        let tBase = UInt16(pData.count)
        
        func zTVertex(_ zpt:simd_float3) -> TVertex {
            var t = TVertex(zpt,color)
            t.nrm = zpt - pos
            t.nrm = normalize(t.nrm)
            t.drawStyle = 1
            return t
        }
                
        pData.append(zTVertex(p1))
        pData.append(zTVertex(p2))
        pData.append(zTVertex(p3))
        pData.append(zTVertex(p4))
        pData.append(zTVertex(p5))
        pData.append(zTVertex(p6))
        pData.append(zTVertex(p7))
        pData.append(zTVertex(p8))
        
        for i in 0 ..< indices.count {
            iData.append(tBase + indices[i])
        }
        
        if pData.count > 0 {
            pBuffer  = gDevice?.makeBuffer(bytes: pData,  length: pData.count  * MemoryLayout<TVertex>.size, options: MTLResourceOptions())
            iBuffer  = gDevice?.makeBuffer(bytes: iData,  length: iData.count  * MemoryLayout<UInt16>.size, options: MTLResourceOptions())
        }
    }
    
    func addPoint(_ pt:CGPoint) {

        if style == 2 {
            addCube(pt)
            return
        }
        
        var x = (Float(pt.x) - bounds.x/2) * 0.01
        let y = -(Float(pt.y) - bounds.y/2) * 0.01
        var z = Float(0)

        let ss = sinf(spinAngle)
        let cc = cosf(spinAngle)

        let qt = x
        x = x * cc - z * ss
        z = qt * ss + z * cc
        
        var r = CGFloat()
        var g = CGFloat()
        var b = CGFloat()
        var a = CGFloat()
        drawColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        pData.append(TVertex(simd_float3(x,y,z), simd_float4(Float(r),Float(g),Float(b),Float(1))))

        if pData.count > 0 {
            pBuffer  = gDevice?.makeBuffer(bytes: pData,  length: pData.count  * MemoryLayout<TVertex>.size, options: MTLResourceOptions())
        }
    }

    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        if pData.count > 0 {
            renderEncoder.setVertexBuffer(pBuffer, offset: 0, index: 0)

            switch style {
            case 0 :
                renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: pData.count)
            case 1 :
                renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: pData.count)
            case 2 :
                renderEncoder.drawIndexedPrimitives(type:.triangle, indexCount: iData.count, indexType: MTLIndexType.uint16, indexBuffer: iBuffer!, indexBufferOffset:0)
            default: break
            }
        }
    }
}
