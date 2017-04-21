//
//  ViewController.swift
//  CodeScanner
//
//  Created by zhuxuhong on 2017/4/19.
//  Copyright © 2017年 zhuxuhong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if let dest = segue.destination as? QRCodeViewController{
            dest.completion = {[unowned self](result)in
                let alert = UIAlertController(title: "扫描结果", message: result, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    @IBAction func actionForButtonClicked(_ sender: UIButton){
        //        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized{
        //
        //        }
    }
}

