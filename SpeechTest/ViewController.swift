//
//  ViewController.swift
//  SpeechTest
//
//  Created by shangkun on 2019/3/13.
//  Copyright © 2019年 wushangkun. All rights reserved.
//

import UIKit
import Speech


/// 识别音频文件

class ViewController: UIViewController ,SFSpeechRecognizerDelegate {

    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var recognizeBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        requestAuthorization()
    }
    
    func recognizeFile(url:NSURL) {
        
        guard let myRecognizer = SFSpeechRecognizer.init(locale: Locale.init(identifier: "zh-CN")) else {
            return
        }
        
        if !myRecognizer.isAvailable {
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url as URL)
        myRecognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                return
            }
            
            self.textView.text = result.bestTranscription.formattedString
            if result.isFinal {
                print("Speech in the file is \(result.bestTranscription.formattedString)")
                self.textView.text = result.bestTranscription.formattedString
            }
        }
    }
    
    @IBAction func recognizeBtnDidClick(_ sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            print("开始识别")
            let path = Bundle.main.path(forResource: "car_train_order", ofType: "mp3")
            let url: NSURL = NSURL.init(fileURLWithPath: path!)
            recognizeFile(url: url)
            
        } else {
            print("停止识别，回到默认")
        }
    }
    
    // MARK: 请求语音识别权限
    func requestAuthorization() {
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            
            print("status = \(status.rawValue)")
            
            OperationQueue.main.addOperation {
                
                var isSpeakBtnEnabled = false
                
                switch status {
                    
                case .notDetermined :
                    
                    isSpeakBtnEnabled = false
                    
                    self.recognizeBtn.setTitle("语音识别还没有经授权", for: .disabled)
                    
                case .denied :
                    
                    isSpeakBtnEnabled = false
                    
                    self.recognizeBtn.setTitle("用户拒绝访问语音识别", for: .disabled)
                    
                    self.perform(#selector(SpeechViewController.openSettings), with: nil, afterDelay: 2)
                    
                case .restricted :
                    
                    isSpeakBtnEnabled = false
                    
                    self.recognizeBtn.setTitle("语音识别不支持此设备", for: .disabled)
                    
                case .authorized :
                    
                    isSpeakBtnEnabled = true
                }
                
                self.recognizeBtn.isEnabled = isSpeakBtnEnabled
            }
        }
    }
    
}

