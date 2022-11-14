//
//  ViewController.swift
//  2d_math_day10
//
//  Created by 김태윤 on 2022/11/14.
//

import UIKit
import MetalKit
class ViewController: UIViewController {
    var renderer: Renderer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: self.view.frame,device: device)
        view.addSubview(mtkView)
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mtkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            mtkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            mtkView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mtkView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        self.view.backgroundColor = .red
        renderer = Renderer(device, mtkView)
    }
}

