//
//  WebResultVC.swift
//  CodeScanner
//
//  Created by zhuxuhong on 2017/5/19.
//  Copyright © 2017年 zhuxuhong. All rights reserved.
//

import UIKit

class WebResultVC: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var dismissBarItem: UIBarButtonItem!
    @IBOutlet weak var goBackBarItem: UIBarButtonItem!
    @IBOutlet weak var goForwardBarItem: UIBarButtonItem!
    @IBOutlet weak var refreshBarItem: UIBarButtonItem!
    
    public var url = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadRequest()
    }
    
    fileprivate func loadRequest(){
        if let URL = URL(string: url){
            webView.loadRequest(URLRequest(url: URL))
        }        
    }
    
    @IBAction func actionForBarItemDidClick(_ sender: UIBarButtonItem)
    {
        switch sender {
            case dismissBarItem:
                dismiss(animated: true, completion: nil)
            
            case goBackBarItem:
                webView.goBack()
            
            case goForwardBarItem:
                webView.goForward()
            
            case refreshBarItem:
                loadRequest()
            
            default: break
        }
    }

}

extension WebResultVC: UIWebViewDelegate{
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        title = "加载网页失败，请刷新重试"
        
        setToolBarItemsState(canRefresh: true, canGoBack: false, canGoForward: false)
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        title = "正在加载网页..."
        
        setToolBarItemsState(canRefresh: false, canGoBack: false, canGoForward: false)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        setToolBarItemsState(canRefresh: true, canGoBack: webView.canGoBack, canGoForward: webView.canGoForward)
        
        title = webView.stringByEvaluatingJavaScript(from: "document.title")
    }
    
    fileprivate func setToolBarItemsState(canRefresh: Bool, canGoBack: Bool, canGoForward: Bool){
        refreshBarItem.isEnabled = canRefresh
        goBackBarItem.isEnabled = canGoBack
        goForwardBarItem.isEnabled = canGoForward
    }
}
