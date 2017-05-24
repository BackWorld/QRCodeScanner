//
//  QRCodeReaderView.swift
//  CodeScanner
//
//  Created by zhuxuhong on 2017/4/19.
//  Copyright © 2017年 zhuxuhong. All rights reserved.
//

import UIKit

class QRCodeReaderView: UIView {
// MARK: - IBOutlet
    @IBOutlet weak var torchBtn: UIButton!
    @IBOutlet weak var overlayIV: UIImageView!
    
    @IBOutlet weak var lineIV: UIImageView!
    @IBOutlet weak var lineIVTopCons: NSLayoutConstraint!

    @IBOutlet weak var tipsLable: UILabel!

// MARK: - properties
    
    fileprivate var scanningFromTop = true
    fileprivate var cons: CGFloat = 0
    
    public lazy var reader: QRCodeReader = {
        let v = QRCodeReader()
        return v
    }()
    
    fileprivate var timer: Timer!
    
    fileprivate lazy var container: UIView = {
        let v: UIView = Bundle.main.loadNibNamed("QRCodeReaderView", owner: self, options: nil)?.first as! UIView
        v.frame = self.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return v
    }()
    
    fileprivate var isTorchOn = false

    deinit
    {
        if timer != nil {
            timer.invalidate()
            timer = nil
        }
    }
}

extension QRCodeReaderView{
    public func setup(completion: @escaping QRCodeReaderCompletion){
        layer.addSublayer(self.reader.previewLayer)
        addSubview(container)
        
        startOverlayAnimation()
        
        reader.startScanning(completion: completion)
        
        torchBtn.isHidden = !QRCodeReader.isTorchAvailable()
        torchBtn.layer.cornerRadius = isIpad() ? 40 : 30
    }
    
    public func updateRectOfOutput(){
        let inset = reader.previewLayer.metadataOutputRectOfInterest(for: overlayIV.frame)
        reader.output.rectOfInterest = inset
    }
}

extension QRCodeReaderView{
    fileprivate func startOverlayAnimation(){
        // 动画
        let duration = 0.006
        if #available(iOS 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: true) {[unowned self]
                (timer) in
                self.actionForScannerBoxAnimation(sender: timer)
            }
            
        } else {
            timer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(QRCodeReaderView.actionForScannerBoxAnimation(sender:)), userInfo: nil, repeats: true)
        }
        timer.fire()
    }
    
    @objc fileprivate func actionForScannerBoxAnimation(sender: Timer){
        let h: CGFloat = isIpad() ? 300 : 200

        if self.cons <= 10{
            scanningFromTop = true
        }
        else if self.cons >= h - 10{
            scanningFromTop = false
        }
        
        if self.scanningFromTop {
            cons += 1
        }
        else{
            cons -= 1
        }
        
        self.lineIVTopCons.constant = self.cons
        self.layoutIfNeeded()
    }
    
    fileprivate func isIpad() -> Bool{
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}

extension QRCodeReaderView{
    override func layoutSubviews() {
        super.layoutSubviews()
        
        reader.previewLayer.frame = bounds
    }
    
    @IBAction func actionForButtonClicked(_ sender: UIButton) {
        if sender == torchBtn{
            isTorchOn = QRCodeReader.toggleTorch(isOn: isTorchOn)
            let title = isTorchOn ? "关闭" : "手电筒"
            sender.setTitle(title, for: .normal)
        }
    }
}

