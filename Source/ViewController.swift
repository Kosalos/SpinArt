import UIKit
import MetalKit

var timer = Timer()
var bounds:simd_float2 = simd_float2()
var style:Int = 0   // 0,1,2 = point,line,cube

class ViewController: UIViewController{
    var renderer: Renderer!
    @IBOutlet var metalView: MetalView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let metalView = metalView else { print("View of Gameview controller is not an MTKView"); return }
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else { print("Metal is not supported"); return }
        
        metalView.device = defaultDevice
        metalView.backgroundColor = UIColor.clear
        
        bounds.x = Float(metalView.bounds.width)
        bounds.y = Float(metalView.bounds.height)

        guard let newRenderer = Renderer(metalKitView: metalView) else { print("Renderer cannot be initialized"); return }
        
        renderer = newRenderer
        renderer.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        metalView.delegate = renderer
    }
    
    @IBAction func resetPressed(_ sender: UIButton) {
        pointCloud.reset()
    }

    @IBAction func styleChanged(_ sender: UISegmentedControl) {
        style = sender.selectedSegmentIndex
        if style == 2 { pointCloud.reset() }  // ensure iData
    }
    
    @IBAction func speedChanged(_ sender: UISlider) {
        spinAngleDelta = 0.01 + sender.value * 2
    }
    
    override var prefersStatusBarHidden: Bool { return true }    
}
