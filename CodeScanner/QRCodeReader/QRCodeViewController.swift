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
        bar.tintColor = UIColor.white
        bar.barTintColor = UIColor(red: 47/255.0, green: 208/255.0, blue: 154/255.0, alpha: 1)
        bar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        let item = UINavigationItem(title: "扫一扫")
        let leftBtn = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(QRCodeViewController.actionForBarButtonItemClicked(_:)))
        let rightBtn = UIBarButtonItem(title: "相册", style: .plain, target: self, action: #selector(QRCodeViewController.actionForBarButtonItemClicked(_:)))
        
//        item.leftBarButtonItem = leftBtn
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
    
    convenience init(completion: QRCodeReaderCompletion?) {
        self.init()
        self.completion = completion
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension QRCodeViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(topBar)
        
        if QRCodeReader.isDeviceAvailable() && !QRCodeReader.isCameraUseDenied(){
            setupReader()
        }
        
        // 监听
        NotificationCenter.default.addObserver(self, selector: #selector(QRCodeViewController.handleNotification(noti:)), name: .UIApplicationWillEnterForeground, object: nil)
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
        
        readerView.reader.session.startRunning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.topViewController as? WebResultVC{
            vc.url = sender as? String ?? ""
        }
    }
    
    // MARK: - action & IBOutletAction
    @IBAction func actionForBarButtonItemClicked(_ sender: UIBarButtonItem){
        guard let item = topBar.items!.first else {
            return
        }
        if let left = item.leftBarButtonItem, sender == left {
            completionFor(result: nil, isCancel: true)
        }
        else if sender == item.rightBarButtonItem! {
            handleActionForImagePicker()
        }
    }
    
    @objc fileprivate func handleNotification(noti: Notification){
        if noti.name == .UIApplicationWillEnterForeground {
            viewDidAppear(false) //刷新摄像头session
        }
    }
    
    fileprivate func completionFor(result: String?, isCancel: Bool){
        if isCancel {
            dismiss(animated: true, completion: nil)
        }
        else if let str = result
        {
            if str.contains("http") || str.contains("https"){
                readerView.reader.stopScanning()
                
                performSegue(withIdentifier: "showWebResultPage", sender: str)
            }
            else if let url = URL(string: str),
                UIApplication.shared.canOpenURL(url){
                readerView.reader.stopScanning()

                UIApplication.shared.openURL(url)
            }
            else{
                let alert = UIAlertController(title: "扫描结果", message: str, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "取消", style: .default, handler: nil))
                alert.addAction(UIAlertAction(title: "复制", style: .cancel, handler: { (action) in
                    UIPasteboard.general.string = str
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}


extension QRCodeViewController{
    fileprivate func handleActionForImagePicker(){
        if QRCodeReader.isAlbumUseDenied() {
            hanldeAlertForAuthorization(isCamera: false)
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
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
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
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
