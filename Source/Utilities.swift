import Foundation
import ARKit

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

extension TVertex {
    init(_ p:float3) {
        self.init()
        pos = p
        nrm = float3()
        txt = float2(0,0)
        color = float4(1,1,1,1)
        drawStyle = 0
    }
    
    init(_ p:float3, _ ncolor:float4) {
        self.init()
        pos = p
        nrm = float3()
        txt = float2(0,0)
        color = ncolor
        drawStyle = 0
    }
}

extension PVertex {
    init(_ p:float3) {
        self.init()
        pos = p
        color = float4(1,1,1,1)
    }
    
    init(_ p:float3, _ ncolor:float4) {
        self.init()
        pos = p
        color = ncolor
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Generic matrix math utility functions
func matrix4x4_rotation(_ radians: Float, _ axis: float3) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

// MARK: - Collection extensions
extension Array where Iterator.Element == Float {
	var average: Float? {
		guard !self.isEmpty else {
			return nil
		}
		
		let sum = self.reduce(Float(0)) { current, next in
			return current + next
		}
		return sum / Float(self.count)
	}
}

extension Array where Iterator.Element == float3 {
	var average: float3? {
		guard !self.isEmpty else {
			return nil
		}
  
        let sum = self.reduce(float3(0)) { current, next in
            return current + next
        }
		return sum / Float(self.count)
	}
}

extension RangeReplaceableCollection { // zorro where IndexDistance == Int {
	mutating func keepLast(_ elementsToKeep: Int) {
		if count > elementsToKeep {
			self.removeFirst(count - elementsToKeep)
		}
	}
}

// MARK: - SCNNode extension

extension SCNNode {
	
	func setUniformScale(_ scale: Float) {
		self.simdScale = float3(scale, scale, scale)
	}
	
	func renderOnTop(_ enable: Bool) {
		self.renderingOrder = enable ? 2 : 0
		if let geom = self.geometry {
			for material in geom.materials {
				material.readsFromDepthBuffer = enable ? false : true
			}
		}
		for child in self.childNodes {
			child.renderOnTop(enable)
		}
	}
}

// MARK: - float4x4 extensions

extension float4x4 {
    /// Treats matrix as a (right-hand column-major convention) transform matrix
    /// and factors out the translation component of the transform.
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
	
	init(_ size: CGSize) {
        self.init()
		self.x = size.width
		self.y = size.height
	}
	
	init(_ vector: SCNVector3) {
        self.init()
		self.x = CGFloat(vector.x)
		self.y = CGFloat(vector.y)
	}
	
	func distanceTo(_ point: CGPoint) -> CGFloat {
		return (self - point).length()
	}
	
	func length() -> CGFloat {
		return sqrt(self.x * self.x + self.y * self.y)
	}
	
	func midpoint(_ point: CGPoint) -> CGPoint {
		return (self + point) / 2
	}
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
    
    static func -= (left: inout CGPoint, right: CGPoint) {
        left = left - right
    }
    
    static func / (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x / right, y: left.y / right)
    }
    
    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }
    
    static func /= (left: inout CGPoint, right: CGFloat) {
        left = left / right
    }
    
    static func *= (left: inout CGPoint, right: CGFloat) {
        left = left * right
    }
}

// MARK: - CGSize extensions

extension CGSize {
	init(_ point: CGPoint) {
        self.init()
		self.width = point.x
		self.height = point.y
	}

    static func + (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width + right.width, height: left.height + right.height)
    }

    static func - (left: CGSize, right: CGSize) -> CGSize {
        return CGSize(width: left.width - right.width, height: left.height - right.height)
    }

    static func += (left: inout CGSize, right: CGSize) {
        left = left + right
    }

    static func -= (left: inout CGSize, right: CGSize) {
        left = left - right
    }

    static func / (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width / right, height: left.height / right)
    }

    static func * (left: CGSize, right: CGFloat) -> CGSize {
        return CGSize(width: left.width * right, height: left.height * right)
    }

    static func /= (left: inout CGSize, right: CGFloat) {
        left = left / right
    }

    static func *= (left: inout CGSize, right: CGFloat) {
        left = left * right
    }
}

// MARK: - CGRect extensions

extension CGRect {
	var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}

func rayIntersectionWithHorizontalPlane(rayOrigin: float3, direction: float3, planeY: Float) -> float3? {
	
    let direction = simd_normalize(direction)

    // Special case handling: Check if the ray is horizontal as well.
	if direction.y == 0 {
		if rayOrigin.y == planeY {
			// The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
			// Therefore we simply return the ray origin.
			return rayOrigin
		} else {
			// The ray is parallel to the plane and never intersects.
			return nil
		}
	}
	
	// The distance from the ray's origin to the intersection point on the plane is:
	//   (pointOnPlane - rayOrigin) dot planeNormal
	//  --------------------------------------------
	//          direction dot planeNormal
	
	// Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
	let dist = (planeY - rayOrigin.y) / direction.y

	// Do not return intersections behind the ray's origin.
	if dist < 0 {
		return nil
	}
	
	// Return the intersection point.
	return rayOrigin + (direction * dist)
}
