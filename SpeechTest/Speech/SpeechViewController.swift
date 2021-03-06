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
    // 创建与指定区域设置关联的语音识别器。 , zh-CN，en-US
    private let recognizer = SFSpeechRecognizer.init(locale: Locale.init(identifier: "zh-CN"))
    private let audioEngine = AVAudioEngine()  // 音频引擎，用于音频输入
    private var audioBufferRequest : SFSpeechAudioBufferRecognitionRequest? // 语音识别的请求
    private var recognitionTask : SFSpeechRecognitionTask?  // 语音识别的任务类
    /// 语音合成器
    lazy private var speechSynthesizer: AVSpeechSynthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        return synthesizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        for value in SFSpeechRecognizer.supportedLocales() {
            print(value.description)
        }
        self.speakBtn.isEnabled = false
        // 表示所请求的语音识别的类型
        recognizer?.defaultTaskHint = .unspecified
        /*
        public enum SFSpeechRecognitionTaskHint : Int {
            
            case unspecified // 未指定识别
            
            case dictation // 案例听写//一般听写/键盘风格
        
            case search // 案例搜索//搜索样式请求
            
            case confirmation // 案例确认//简短，确认样式请求（“是”、“否”、“可能”）
        }
         */
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        recognizer?.delegate = self
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
    
    func openUrl(string: String) {
        let url = URL(string: string)
        if UIApplication.shared.canOpenURL(url!) {
            UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
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
            
            if let results = dataResult["results"].array {
                
                for dic in results {
                    
                    if let resultType = dic["resultType"].string {
                        
                        if resultType == "text" {
                            
                            let text = dic["values"]["text"].string
                            
                            print("text = \(text!)" )
                            
                            self.appendString(text!, contentType: .Your)
                            
                        } else if resultType == "url" {
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: {
                                
                                self.openUrl(string:  dic["values"]["url"].string!)
                            })
                        }
                    }
                }
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
            self.tableView.insertRows(at: [IndexPath(row: self.dataArray.count - 1, section: 0)], with: contentType == .Mine ? .fade : .left)
            self.tableView.scrollToRow(at: IndexPath(row: self.dataArray.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
            
            if contentType == .Your {
                self.text_to_speech(string)
            }
        }
    }
    
    func text_to_speech( _ string: String) {
        
        if self.speechSynthesizer.isPaused {
            self.speechSynthesizer.continueSpeaking()
        } else if self.speechSynthesizer.isSpeaking {
            self.speechSynthesizer.pauseSpeaking(at: .immediate)
        } else {
            // 声带
            let utterance = AVSpeechUtterance(string: string)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.preUtteranceDelay = 0.25 // 播放当前语句前的间歇时间
            utterance.postUtteranceDelay = 0.25 // 播放下一句的间歇时间
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN") // 语言的种类
            utterance.volume = 1.0//音量
            utterance.pitchMultiplier = 1.0 // 声音的音调, 一般在[0.5 - 2]，默认值是1。
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
               try! startRecording()
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

extension SpeechViewController: SFSpeechRecognizerDelegate,SFSpeechRecognitionTaskDelegate {
    
    // MARK: 请求语音识别权限
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
    
    
    func startRecording() throws {
    
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
       
//        guard (recognizer?.isAvailable)! else {
//            fatalError("recognizer is not available")
//        }
      
        // do - catch

        let audioSession = AVAudioSession.sharedInstance() // 管理音频硬件资源的分配
        try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord) // AVAudioSessionCategoryRecord
        try audioSession.setMode(AVAudioSessionModeMeasurement) // 场景： 最小系统 、VoIP、 游戏录制、录制视频、视频播放、视频通话
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        // inputNode、outputNode分别对应硬件的麦克风和扬声器
        let inputNode:AVAudioInputNode = audioEngine.inputNode  // 输入

        audioBufferRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = audioBufferRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") } // 致命错误
       
        // 设置在音频录制完成之前返回结果
        // 每产生一种结果就马上返回
        recognitionRequest.shouldReportPartialResults = true
        // 标识符字符串。
        // 识别请求: 可用于由开发人员识别接收者的字符串
        recognitionRequest.interactionIdentifier = "myaudiorequest"
       
        // 保留对该任务的引用，以便取消该任务。
        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (recognitionResult, error) in
            var isFinal = false
            if let result = recognitionResult {
                isFinal = result.isFinal
                
                print(">>>>>>>>>>>>>:\(result.bestTranscription.formattedString)")
                
                if isFinal {
                    
                    let string = result.bestTranscription.formattedString  // 语音转换后的信息类
                    
                    for transcriptionSegment in result.bestTranscription.segments {
                        
                        print("substring =  \(transcriptionSegment.substring)")
                    }
                    
                    self.appendString(string, contentType: .Mine)
                    
                    if string.contains("微信") {
                        
                        self.openUrl(string: "weixin://")
                    }
                    
                    self.requestTuringRot(string: string)
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
        
        // recognitionTask = recognizer?.recognitionTask(with: recognitionRequest, delegate: self)
    
        // 数字音频采样的格式
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        //在添加tap之前先移除上一个 否则可能报"*** Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio', reason: 'required condition is false: nullptr == Tap()"之类的错误
        inputNode .removeTap(onBus: 0)
        // bufferSize:传入缓冲区的请求大小
        // 创建一个“tap”来记录/监视/观察节点的输出
        // bus：连接tap的节点输出总线
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer:AVAudioPCMBuffer, when: AVAudioTime) in
            self?.audioBufferRequest?.append(buffer) // 拼接 音频缓冲数据
        }
        
        if audioEngine.isRunning {
            audioEngine.stop()
            audioBufferRequest?.endAudio()
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    // 监控语音识别的可用性
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.speakBtn.isEnabled = true
        } else {
            self.speakBtn.isEnabled = false
        }
    }
    
    // MARK: SFSpeechRecognitionTaskDelegate
    
    // 当任务首次检测到源音频中的语音时
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
       
        print("speechRecognitionDidDetectSpeech = \(task.description)")
    }
    
    // 告诉代理该任务已被取消。
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
       
        print("speechRecognitionTaskWasCancelled = \(task.description)")
    }
    
    // 当任务不再接受新的音频输入时，即使最终处理正在进行，也告诉代理
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        
        print("speechRecognitionTaskFinishedReadingAudio = \(task.description)")
    }
    
    // 完成对所有请求的话语的识别。
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        
        print("didFinishSuccessfully = \(successfully)")
    }
    
    // 告诉代理可以使用假设的转录。
    // 持续回调
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        
        print("didHypothesizeTranscription = \(transcription.formattedString)")
    }
    
    // 仅为最终识别话语而调用。将不再报道关于话语的事件
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
       
        print("didFinishRecognition = \(recognitionResult.bestTranscription.formattedString)")
        let string = recognitionResult.bestTranscription.formattedString  // 语音转换后的信息类
        self.appendString(string, contentType: .Mine)
        self.requestTuringRot(string: string)
    }
    
    /*
    开始说话
    didHypothesizeTranscription = 你
    didHypothesizeTranscription = 你在
    didHypothesizeTranscription = 你在干嘛？
    didHypothesizeTranscription = 你在干嘛呢？
    didHypothesizeTranscription = 你在干嘛呢？
    停止说话，回到默认
    speechRecognitionTaskFinishedReadingAudio = <_SFSpeechRecognitionDelegateTask: 0x60c0000ce770>
    didHypothesizeTranscription = 你在干嘛呢？
    didFinishRecognition = 你在干嘛呢？
    didFinishSuccessfully = true
    */
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
        // let str = (utterance.speechString as NSString).substring(with: characterRange)
        // print(str)
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
