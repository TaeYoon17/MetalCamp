//
//  ViewController.swift
//  Drawing in 2D
//
//  Created by 김태윤 on 2022/11/13.
//

import UIKit
import MetalKit
class ViewController: UIViewController {
    var renderer: Renderer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView:MTKView = MTKView(frame: self.view.frame,device: device)
        self.view.addSubview(mtkView)
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mtkView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mtkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mtkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            mtkView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        self.renderer = Renderer(device: device, view: mtkView)
    }
}

