//
//  ViewController.swift
//  chapter3
//
//  Created by 김태윤 on 2022/11/03.
//

import UIKit
import MetalKit
class ViewController: UIViewController{
    var renderer: Renderer?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let metalView = view as? MTKView else{
            fatalError("metal view not set up in storyboard")
        }
        renderer = Renderer(metalView: metalView)
    }
}

