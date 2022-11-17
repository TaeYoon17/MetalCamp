//
//  ViewController.swift
//  mesh_day11
//
//  Created by 김태윤 on 2022/11/15.
//

import UIKit
import MetalKit
class ViewController: UIViewController {
    var renderer: Renderer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let device = MTLCreateSystemDefaultDevice()!
        let metalView = MTKView(frame: self.view.frame,device: device)
        self.view.addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            metalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metalView.topAnchor.constraint(equalTo: view.topAnchor),
            metalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        renderer = Renderer(metalView, device)
    }


}

