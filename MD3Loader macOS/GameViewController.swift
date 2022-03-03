//
//  GameViewController.swift
//  MD3Loader macOS
//
//  Created by Richard Pickup on 18/02/2022.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {

    var renderer: Renderer!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }

        // Select the device to render with.  We choose the default device
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }

        mtkView.device = defaultDevice

        let newRenderer = Renderer(metalView: mtkView)

        renderer = newRenderer

        renderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)

        mtkView.delegate = renderer
        
        addGestureRecognizers(to: mtkView)
    }
}

extension GameViewController {
    func addGestureRecognizers(to view: NSView) {
        let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(pan)
    }
    
    @objc func handlePan(gesture: NSPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        let delta = float2(Float(translation.x), Float(translation.y))
        renderer.camera.rotate(delta: delta)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    override func scrollWheel(with event: NSEvent) {
        renderer.camera.zoom(delta: Float(event.deltaY))
    }
}
