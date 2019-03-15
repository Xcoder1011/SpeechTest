//
//  SpeechViewController.swift
//  SpeechTest
//
//  Created by shangkun on 2019/3/13.
//  Copyright © 2019年 wushangkun. All rights reserved.
//

import UIKit
import Speech

// 图灵： 480ffd93a93441aba6f66f029287a314
class SpeechViewController: UIViewController {

    let api = "http://openapi.tuling123.com/openapi/api/v2"
    
    @IBOutlet weak var speakBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    lazy var dataArray = NSMutableArray()
    lazy var dataArray1 = []

    // 创建与用户的默认语言设置关联的语音识别器。
    // var recognizer = SFSpeechRecognizer.init()
    // 创建与指定区域设置关联的语音识别器。 , zh-CN，en-US
    private let recognizer = SFSpeechRecognizer.init(locale: Locale.init(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var audioBufferRequest : SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask : SFSpeechRecognitionTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension

        // print("SFSpeechRecognizer.supportedLocales() = \(SFSpeechRecognizer.supportedLocales())")
        for value in SFSpeechRecognizer.supportedLocales() {
            print(value.description)
        }
        //  监视语音识别服务可用性的更改
        recognizer?.delegate = self
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestAuthorization()
    }
    
    @objc func openSettings() {
        
        let alert = UIAlertController.init(title: "提示", message: "去打开语音识别权限？", preferredStyle: .alert)
        let cancelAction = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        let openAction = UIAlertAction.init(title: "去打开", style: .default) { (action) in
            
            let url = URL(string: UIApplicationOpenSettingsURLString)
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(openAction)
        alert.show(self, sender: nil)
        present(alert, animated: true, completion: nil)
    }
    
    
    /// speak按钮点击
    @IBAction func speakBtnClicked(_ sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            print("开始说话")
            if audioEngine.isRunning {
                audioEngine.stop()
                audioBufferRequest?.endAudio()
                sender.isSelected = false
            } else {
                startRecording()
            }
        } else {
            print("停止说话，回到默认")
            if audioEngine.isRunning {
                audioEngine.stop()
                audioBufferRequest?.endAudio()
                sender.isSelected = false
            }
        }
    }
}

extension SpeechViewController : SFSpeechRecognizerDelegate {
    
    //MARK:  请求语音识别权限
    func requestAuthorization() {
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            
            print("status = \(status.rawValue)")
            
            OperationQueue.main.addOperation {
                
                var isSpeakBtnEnabled = false
                
                switch status {
                    
                case .notDetermined :
                    
                    isSpeakBtnEnabled = false
                    
                    self.speakBtn.setTitle("语音识别还没有经授权", for: .disabled)
                    
                case .denied :
                    
                    isSpeakBtnEnabled = false
                    
                    self.speakBtn.setTitle("用户拒绝访问语音识别", for: .disabled)
                    
                    self.perform(#selector(SpeechViewController.openSettings), with: nil, afterDelay: 2)
                    
                case .restricted :
                    
                    isSpeakBtnEnabled = false
                    
                    self.speakBtn.setTitle("语音识别不支持此设备", for: .disabled)
                    
                case .authorized :
                    
                    isSpeakBtnEnabled = true
                }
                
                self.speakBtn.isEnabled = isSpeakBtnEnabled
            }
        }
    }
    
    
    func startRecording() {
    
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
      
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
                    
        } catch  {
            print("audioSession can not setted.")
        }
        
        audioBufferRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode:AVAudioInputNode = audioEngine.inputNode
        
        guard let recognitionRequest = audioBufferRequest else {
            fatalError("can not create SFSpeechAudioBufferRecognitionRequest")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (recognitionResult, error) in
          
            //print(recognitionResult?.bestTranscription.formattedString as Any)
            var isFinal = false
            if recognitionResult != nil {
                isFinal = (recognitionResult?.isFinal)!
                if isFinal {
                    self.dataArray.add(recognitionResult?.bestTranscription.formattedString as Any)
                    self.tableView.insertRows(at: [IndexPath(row: self.dataArray.count - 1, section: 0)], with: UITableViewRowAnimation.left)
                    self.tableView.scrollToRow(at: IndexPath(row: self.dataArray.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.audioBufferRequest = nil
                self.recognitionTask = nil
                self.speakBtn.isSelected = false
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        //在添加tap之前先移除上一个 否则可能报"*** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'required condition is false: nullptr == Tap()"之类的错误
        inputNode .removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, when) in
            self?.audioBufferRequest?.append(buffer)
        }
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioBufferRequest?.endAudio()
        }
        
        audioEngine.prepare()  //12
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    
    }
    
    //MARK: SFSpeechRecognizerDelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        print("availabilityDidChange = \(available)")
        if available {
            self.speakBtn.isEnabled = true
        } else {
            self.speakBtn.isEnabled = false
        }
    }
    
}

extension SpeechViewController: UITableViewDelegate, UITableViewDataSource {
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpeechViewYouCell", for:indexPath) as! SpeechViewYouCell
        let string = dataArray[indexPath.row] as! String
        cell.contentLabel.text = string
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
