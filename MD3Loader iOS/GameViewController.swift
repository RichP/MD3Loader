//
//  GameViewController.swift
//  MD3Loader iOS
//
//  Created by Richard Pickup on 18/02/2022.
//

import UIKit
import MetalKit

// Our iOS specific view controller
class GameViewController: UIViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }

        mtkView.device = defaultDevice
        mtkView.backgroundColor = UIColor.black

        let newRenderer = Renderer(metalView: mtkView)

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        
        addGestureRecognizers(to: mtkView)
    }
}

extension GameViewController {
    func addGestureRecognizers(to view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(gesture:)))
        view.addGestureRecognizer(pinch)
    }
    
    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let delta = float2(Float(translation.x), Float(translation.y))
        renderer.camera.rotate(delta: delta)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    @objc func handlePinch(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began || gesture.state == .changed {
            
            let scale = gesture.scale >= 1 ? gesture.scale : 0 - gesture.scale
            
            renderer.camera.zoom(delta: Float(scale * 10.0))
           
            gesture.scale = 1.0
            
        }
    }
    
    
}
