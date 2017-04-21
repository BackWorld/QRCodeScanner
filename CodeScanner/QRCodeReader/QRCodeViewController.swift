//
//  QRCodeViewController.swift
//  CodeScanner
//
//  Created by zhuxuhong on 2017/4/19.
//  Copyright © 2017年 zhuxuhong. All rights reserved.
//

import UIKit

class QRCodeViewController: UIViewController {
    fileprivate lazy var topBar: UINavigationBar = {
        let bar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 64))
        bar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        
        let item = UINavigationItem(title: "扫一扫")
        let leftBtn = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(QRCodeViewController.actionForBarButtonItemClicked(_:)))
        let rightBtn = UIBarButtonItem(title: "相册", style: .plain, target: self, action: #selector(QRCodeViewController.actionForBarButtonItemClicked(_:)))
        
        item.leftBarButtonItem = leftBtn
        item.rightBarButtonItem = rightBtn
        
        bar.items = [item]
        
        return bar
    }()
    
    fileprivate lazy var readerView: QRCodeReaderView = {
        let h = self.topBar.bounds.height
        let frame = CGRect(x: 0, y: h, width: self.view.bounds.width, height: self.view.bounds.height-h)
        let v = QRCodeReaderView(frame: frame)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return v
    }()
    
    public var completion: QRCodeReaderCompletion?
    
}

extension QRCodeViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(topBar)
        
        if QRCodeReader.isDeviceAvailable() && !QRCodeReader.isCameraUseDenied(){
            setupReader()
        }
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        
        guard QRCodeReader.isDeviceAvailable() else{
            let alert = UIAlertController(title: "Error", message: "相机无法使用", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: {
                _ in
                self.dismiss(animated: true, completion: nil)
            }))
            present(alert, animated: true, completion: nil)
            return
        }
        
        if QRCodeReader.isCameraUseDenied(){
            hanldeAlertForAuthorization(isCamera: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if QRCodeReader.isCameraUseAuthorized(){
            readerView.updateRectOfOutput()
        }
    }
    
    // MARK: - action & IBOutletAction
    @IBAction func actionForBarButtonItemClicked(_ sender: UIBarButtonItem){
        guard let item = topBar.items!.first else {
            return
        }
        if sender == item.leftBarButtonItem! {
            completionFor(result: nil, isCancel: true)
        }
        else if sender == item.rightBarButtonItem! {
            handleActionForImagePicker()
        }
    }
    
    fileprivate func completionFor(result: String?, isCancel: Bool){
        readerView.reader.stopScanning()
        
        dismiss(animated: true, completion: {
            isCancel ? nil : self.completion?(result ?? "没有发现任何信息")
        })
    }
}


extension QRCodeViewController{
    fileprivate func handleActionForImagePicker(){
        if QRCodeReader.isAlbumUseDenied() {
            hanldeAlertForAuthorization(isCamera: false)
            return
        }
        
        readerView.reader.stopScanning()
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        picker.allowsEditing = false
        
        present(picker, animated: true, completion: nil)
    }
    
    fileprivate func setupReader(){
        view.addSubview(readerView)
        
        readerView.setup(completion: {[unowned self]
            (result) in
            self.completionFor(result: result, isCancel: false)
        })
    }
    
    fileprivate func openSystemSettings(){
        let url = URL(string: UIApplicationOpenSettingsURLString)!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    fileprivate func hanldeAlertForAuthorization(isCamera: Bool){
        let str = isCamera ? "相机" : "相册"
        let alert = UIAlertController(title: "\(str)没有授权", message: "在[设置]中找到应用，开启[允许访问\(str)]", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "去设置", style: .cancel, handler: { _ in
            self.openSystemSettings()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func handleQRCodeScanningFor(image: UIImage){
        let ciimage = CIImage(cgImage: image.cgImage!)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        if let features = detector?.features(in: ciimage),
            let first = features.first as? CIQRCodeFeature{
            self.completionFor(result: first.messageString, isCancel: false)
        }
    }
}

extension QRCodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
        readerView.reader.startScanning(completion: completion)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            picker.dismiss(animated: true, completion: {
                self.handleQRCodeScanningFor(image: image)
            })
        }
    }
}


extension QRCodeViewController{
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if QRCodeReader.isDeviceAvailable() && QRCodeReader.isCameraUseAuthorized() {
            readerView.updateRectOfOutput()
        }
    }
}
