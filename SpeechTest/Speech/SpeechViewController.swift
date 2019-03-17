//
//  SpeechViewController.swift
//  SpeechTest
//
//  Created by shangkun on 2019/3/13.
//  Copyright © 2019年 wushangkun. All rights reserved.
//

import UIKit
import Speech
import SwiftyJSON
import AVFoundation

struct Key {
    struct Turing {
        static let api = "http://openapi.tuling123.com/openapi/api/v2"
        static let apiKey = "480ffd93a93441aba6f66f029287a314" // 图灵
    }
}

enum ContentType:Int {
    case Your
    case Mine
}

class Content  {
    var string: String?
    var contentType: ContentType = .Mine
    init(string: String, contentType: ContentType) {
        self.string = string
        self.contentType = contentType
    }
}

class SpeechViewController: UIViewController {
    
    @IBOutlet weak var speakBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    lazy var dataArray = NSMutableArray()

    // 创建与用户的默认语言设置关联的语音识别器。
    // var recognizer = SFSpeechRecognizer.init()
    // 创建与指定区域设置关联的语音识别器。 , zh-CN，en-US
    private let recognizer = SFSpeechRecognizer.init(locale: Locale.init(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()
    private var audioBufferRequest : SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask : SFSpeechRecognitionTask?

    /// 语音合成
    lazy private var speechSynthesizer: AVSpeechSynthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        return synthesizer
    }()
    
    
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
    
    func requestTuringRot(string: String) {
        
        let param = ["userInfo":["apiKey":Key.Turing.apiKey,
                                 "userId":99],
                     "perception":["inputText":["text":string]],
                     "reqType":0] as [String : Any]
        
        let paramstring = jsonStringFromDictionary(param)
        let config = URLSessionConfiguration.default
        var request = URLRequest.init(url: URL(string: Key.Turing.api)!)
        request.httpMethod = "POST"
        request.httpBody = paramstring.data(using: .utf8)
        
        let session = URLSession.init(configuration: config)
        let task = session.dataTask(with: request) { (data, response, error) in
            
            let dataResult = JSON(data as Any)
            // print("dic = \(dataResult)")
            if let text = dataResult["results"][0]["values"]["text"].string {
                print("text = \(text)" )
                self.appendString(text, contentType: .Your)
            }
        }
        task.resume()
        
        /*
        dic = {
            emotion =     {
                robotEmotion =         {
                    a = 0;
                    d = 0;
                    emotionId = 0;
                    p = 0;
                };
                userEmotion =         {
                    a = 0;
                    d = 0;
                    emotionId = 21500;
                    p = 0;
                };
            };
            intent =     {
                actionName = "";
                code = 10004;
                intentName = "";
            };
            results =     (
                {
                    groupType = 1;
                    resultType = text;
                    values =             {
                        text = "\U6211\U5728\U5077\U5077\U7684\U60f3\U4f60\U6ca1\U53d1\U73b0\U5417\Uff1f";
                    };
                }
            );
        }
       
   */
    }
    
    func jsonStringFromDictionary( _ dic: Dictionary<String, Any>) -> String {
        
        if (!JSONSerialization.isValidJSONObject(dic)) {
            print("无法解析出JSONString")
            return ""
        }
        
        let data = try? JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        let string = String.init(data: data!, encoding: .utf8)
        return string!
    }
    
    func appendString( _ string: String, contentType: ContentType) {
        
        OperationQueue.main.addOperation {
            
            guard !string.isEmpty else { return }
            let mode = Content(string: string, contentType: contentType)
            mode.contentType = contentType
            mode.string = string
            self.dataArray.add(mode)
            self.tableView.insertRows(at: [IndexPath(row: self.dataArray.count - 1, section: 0)], with: UITableViewRowAnimation.fade)
            self.tableView.scrollToRow(at: IndexPath(row: self.dataArray.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            
            if contentType == .Your {
                self.text_to_speech(string)
            }
        }
    }
    
    func text_to_speech( _ string: String) {
        
        /*
         let audioSession = AVAudioSession.sharedInstance()
         do {
         try audioSession.setCategory(AVAudioSessionCategoryPlayback)
         } catch  {
         print("audioSession can not setted.")
         } */
        
        if self.speechSynthesizer.isPaused {
            self.speechSynthesizer.continueSpeaking()
        } else if self.speechSynthesizer.isSpeaking {
            self.speechSynthesizer.pauseSpeaking(at: .immediate)
        } else {
            let utterance = AVSpeechUtterance(string: string)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.preUtteranceDelay = 0.25
            utterance.postUtteranceDelay = 0.25
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            utterance.volume = 1.0//音量
            utterance.pitchMultiplier = 1.0
            utterance.postUtteranceDelay = 1;
            print("speaking string ===== \(string)")
            self.speechSynthesizer.speak(utterance)
        }
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

extension SpeechViewController: SFSpeechRecognizerDelegate {
    
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
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
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
          
            var isFinal = false
            if recognitionResult != nil {
                isFinal = (recognitionResult?.isFinal)!
                if isFinal {
                    let string = recognitionResult?.bestTranscription.formattedString
                    self.appendString(string!, contentType: .Mine)
                    self.requestTuringRot(string: string!)
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
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        //在添加tap之前先移除上一个 否则可能报"*** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'required condition is false: nullptr == Tap()"之类的错误
        inputNode .removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, when) in
            self?.audioBufferRequest?.append(buffer)
        }
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioBufferRequest?.endAudio()
        }
        
        audioEngine.prepare()
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

extension SpeechViewController: AVSpeechSynthesizerDelegate {
    
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        //
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
       
        self.speechSynthesizer.stopSpeaking(at: .immediate)
        
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        //
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        //
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        //
    }
    
    // 监听 播放 字符范围
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let str = (utterance.speechString as NSString).substring(with: characterRange)
        print(str)
    }
}


extension SpeechViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: SpeechContentCell
        let content = dataArray[indexPath.row] as! Content
        switch content.contentType {
        case .Mine:
            cell = tableView.dequeueReusableCell(withIdentifier: "SpeechViewMyCell", for:indexPath) as! SpeechViewMyCell
        case .Your:
            cell = tableView.dequeueReusableCell(withIdentifier: "SpeechViewYouCell", for:indexPath) as! SpeechViewYouCell
        }
        cell.content = content
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
