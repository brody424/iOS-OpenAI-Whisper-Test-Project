//
//  ViewController.swift
//  iOS_OpenAI_Whisper_Test
//
//  Created by Brody Byun on 3/5/24.
//

import UIKit
import Alamofire
import AVFoundation

// https://platform.openai.com/docs/guides/text-to-speech
// https://platform.openai.com/docs/models/dall-e
class ViewController: UIViewController {
    
    let apiKey = "Insert Api Key"
    let url = "https://api.openai.com/v1/audio/speech"
    var audioPlayer: AVAudioPlayer?
    
    @IBOutlet weak var speedTitleLabel: UILabel!
    @IBOutlet weak var speedSlider: UISlider!
    
    @IBOutlet weak var ttsButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var voiceButton: UIButton!
    @IBOutlet weak var outputFormatButton: UIButton!
    @IBOutlet weak var ttsModelButton: UIButton!
    
    var voice: Voice = .alloy
    var ttsModel: TtsModel = .tts
    var outputFormat: OutputFormat = .mp3
    var speed: Float = 1.0
    
    enum Voice: String, CaseIterable {
        case alloy
        case echo
        case fable
        case onyx
        case nova
        case shimmer
    }
    
    enum TtsModel: String, CaseIterable {
        case tts = "tts-1"
        case ttsWithHd = "tts-1-hd"
    }
    
    enum OutputFormat: String, CaseIterable {
        case mp3
        case opus
        case aac
        case flac
        case pcm
    }
    
    struct ErrorResponse: Decodable {
        let error: ErrorDetail
        
        struct ErrorDetail: Decodable {
            let message: String?
            let type: String?
            let code: String?
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextView()
        
        updateButtonTitles()
        
    }
    
    func configureTextView() {
        textView.layer.cornerRadius = 8.0
    }
    
    func updateButtonTitles() {
        voiceButton.setTitle(voice.rawValue, for: .normal)
        outputFormatButton.setTitle(outputFormat.rawValue, for: .normal)
        ttsModelButton.setTitle(ttsModel.rawValue, for: .normal)
    }
    
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        speed = sender.value
        speedTitleLabel.text = "Speed : \(String(format: "%.1f", speed))"
    }
    
    @IBAction func voiceButtonTouched(_ sender: Any) {
        let alertController = UIAlertController(title: "Change Voice", message: nil, preferredStyle: .actionSheet)
        
        Voice.allCases.forEach { voice in
            alertController.addAction(UIAlertAction(title: voice.rawValue, style: .default, handler: { _ in
                self.voice = voice
                self.updateButtonTitles()
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alertController, animated: true)
    }
    
    @IBAction func outputFormatButtonTouched(_ sender: Any) {
        let alertController = UIAlertController(title: "Change Output Format", message: nil, preferredStyle: .actionSheet)
        
        OutputFormat.allCases.forEach { outputFormat in
            alertController.addAction(UIAlertAction(title: outputFormat.rawValue, style: .default, handler: { _ in
                self.outputFormat = outputFormat
                self.updateButtonTitles()
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alertController, animated: true)
    }
    
    
    @IBAction func ttsModelButtonTouched(_ sender: Any) {
        let alertController = UIAlertController(title: "Change TTS Model", message: nil, preferredStyle: .actionSheet)
        
        TtsModel.allCases.forEach { ttsModel in
            alertController.addAction(UIAlertAction(title: ttsModel.rawValue, style: .default, handler: { _ in
                self.ttsModel = ttsModel
                self.updateButtonTitles()
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alertController, animated: true)
    }
    
    @IBAction func ttsFire(_ sender: Any) {
        guard let text = textView.text, text.isEmpty == false else { return }
        let headers: HTTPHeaders =  [
            "Content-type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let requestData = [
            "model": ttsModel.rawValue,
            "input": text,
            "voice": voice.rawValue,
            "response_format": outputFormat.rawValue,
            "speed": "\(String(format: "%.1f", speed))"
        ]
        
        AF.request(url,
                   method: .post,
                   parameters: requestData,
                   encoding: JSONEncoding.default,
                   headers: headers)
        .response { [weak self] response in
            switch response.result {
            case .success(let data):
                guard let data else { 
                    print("Data nil error")
                    return
                }
                
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    print(errorResponse)
                    let alertController = UIAlertController(title: errorResponse.error.code ?? "Error", message: errorResponse.error.message ?? "-", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
                    self?.present(alertController, animated: true)
                } else {
                    self?.playAudio(data: data)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func playAudio(data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print(error.localizedDescription)
        }
    }
    
}



extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("\(#function)")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("\(#function)")
    }
}
