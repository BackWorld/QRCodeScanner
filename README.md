# QRCodeScanner
A QRCode camera scanning and photo album QRCode image recognizer project.

简书地址: http://www.jianshu.com/p/fe7abb7eb069

### 效果：

![iPad横屏](http://upload-images.jianshu.io/upload_images/1334681-d637ccedede2e987.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 要求：
- Platform: iOS8.0+ 
- Language: Swift3.0
- Editor: Xcode8
- Adaptive: 适配横竖屏+所有设备

### 原理：
- xib布局 + AVFoundation
- xib布局

![竖屏](http://upload-images.jianshu.io/upload_images/1334681-6dd3744d68e6d6a2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![横屏](http://upload-images.jianshu.io/upload_images/1334681-f899b99cb2964a7e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- 扫描框为和扫描线均为UIImageView，可自行替换
- 支持手电筒照明功能
- 核心代码

```
// QRCodeReader.swift
//1. 视频捕获设备
    public let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    
 //2. 捕获元数据输出对象
    public lazy var output: AVCaptureMetadataOutput = {
        let v = AVCaptureMetadataOutput()
        v.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        return v
    }()

//3. 捕获会话对象
    public lazy var session: AVCaptureSession = {
        let v = AVCaptureSession()
        v.sessionPreset = AVCaptureSessionPresetHigh
        
        if let input = try? AVCaptureDeviceInput(device: self.device),
            v.canAddInput(input){
            v.addInput(input)
        }
        if v.canAddOutput(self.output) {
            v.addOutput(self.output)
            if !self.output.availableMetadataObjectTypes.isEmpty {
                self.output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            }
        }
        
        return v
    }()
    
//4. 视频预览层视图
    public lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let v = AVCaptureVideoPreviewLayer(session: self.session)
        v?.videoGravity = AVLayerVideoGravityResizeAspectFill
        v?.connection.videoOrientation = self.videoOrientation(interfaceOrientation: UIApplication.shared.statusBarOrientation)
        return v!
    }()

```
- 关键公用方法

```
// 开始扫描
    public func startScanning(completion: QRCodeReaderCompletion?){
        self.completion = completion
        self.session.startRunning()
    }
// 停止扫描
    public func stopScanning(){
        self.session.stopRunning()
    }
```
- 扫描输出代理方法

```
extension QRCodeReader: AVCaptureMetadataOutputObjectsDelegate{
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!)
    {
        if !metadataObjects.isEmpty,
            let data = metadataObjects.first as? AVMetadataMachineReadableCodeObject
        {
            stopScanning()
            completion?(data.stringValue)
        }
    }
}
```

### 用法：
- 代码方式
```
let vc = QRCodeViewController {[unowned self] (result) in
     print("扫描结果: \(result)")
}
// 显示扫一扫界面
present(vc, animated: true, completion: nil)
```
- storyboard方式

![在storyboard上拖拽一个viewcontroller](http://upload-images.jianshu.io/upload_images/1334681-dec6c8bdfb6404fe.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

```
override func prepare(for segue: UIStoryboardSegue, sender: Any?){
      if let vc = segue.destination as? QRCodeViewController{
          vc.completion = {[unowned self](result)in
              print("扫描结果: \(result)")
          }
      }
}
```

> 如果对你有帮助，别忘了给个⭐️哦。

