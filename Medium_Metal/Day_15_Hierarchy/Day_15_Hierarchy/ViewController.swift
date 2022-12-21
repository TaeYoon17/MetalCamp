//
//  ViewController.swift
//  Day_15_Hierarchy
//
//  Created by 김태윤 on 2022/12/21.
//

import UIKit
import MetalKit
class ViewController: UIViewController {

    @IBOutlet weak var mtkView: MTKView!
    var renderer: Renderer!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let device = MTLCreateSystemDefaultDevice()!
        self.renderer = Renderer(device: device, view: mtkView)
    }


}

