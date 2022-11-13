//
//  ViewController.swift
//  mtkView_day4
//
//  Created by 김태윤 on 2022/11/13.
//

import UIKit
import MetalKit
class ViewController: UIViewController {
    var metalView: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.device = MTLCreateSystemDefaultDevice()!
        guard let library = device.makeDefaultLibrary() else{
            fatalError("Unable to create default shader library")
        }
        settingLibirary(library)
        self.metalView = MTKView(frame: self.view.frame, device: self.device)
        self.commandQueue = device.makeCommandQueue()!
        self.metalView.clearColor = MTLClearColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        self.view.addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: 0),
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor,constant: 0),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: 0),
            metalView.topAnchor.constraint(equalTo: self.view.topAnchor,constant: 0)
        ])
        self.metalView.delegate = self
    }
}

extension ViewController: MTKViewDelegate{
    fileprivate func settingLibirary(_ library:MTLLibrary){
        for name in library.functionNames{
            let function = library.makeFunction(name: name)!
            print("\(function)")
        }
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = self.commandQueue.makeCommandBuffer() else{ return}
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            print("Didn't get a render pass descriptor from MTKView; dropping frame...")
            return
        }
        let renderPassEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        renderPassEncoder.endEncoding()
        // GPU가 그릴 수 있는 다음 상태가 존재하면 그린다.
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    
}
