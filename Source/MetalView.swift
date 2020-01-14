import Metal
import MetalKit
import simd

var vector = CGVector()
var drawColor = UIColor()

class MetalView: MTKView {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            vector = t.azimuthUnitVector(in:nil)
            drawColor = UIColor(hue:CGFloat( Float(1 - abs(vector.dx))), saturation: 1.0, brightness: 1.0, alpha: abs(vector.dy))

            pointCloud.addPoint(t.location(in: self))
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { touchesBegan(touches, with:event) }
}

