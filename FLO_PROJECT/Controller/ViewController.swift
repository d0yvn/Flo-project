//
//  ViewController.swift
//  FLO_PROJECT
//
//  Created by doyun on 2021/11/12.
//

import UIKit
import Alamofire
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var musicTitle: UILabel!
    @IBOutlet weak var singer: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var lyrics: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var onoffButton: UIButton!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    
    var musicPlayerManager = MusicPlayerManager.shared
    var timerObserverToken:Any?
    
    var lyricsArray = [Lyrics]()
    var totalTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //        image.layer.masksToBounds = true
        //        image.layer.cornerRadius = 8
        
        let tapGestrue = UITapGestureRecognizer(target: self, action: #selector(ViewController.tap))
        lyrics.isUserInteractionEnabled = true
        lyrics.addGestureRecognizer(tapGestrue)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        callAPI()
    }
    
    
    @IBAction func buttonClicked(_ sender: UIButton) {
        if musicPlayerManager.player?.rate == 0 {
            onoffButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            musicPlayerManager.player?.play()
        } else {
            onoffButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            musicPlayerManager.player?.pause()
        }
    }
    
    
    func callAPI() {
        let url = "https://grepp-programmers-challenges.s3.ap-northeast-2.amazonaws.com/2020-flo/song.json"
        AF.request(url).validate(statusCode: 200..<300).responseJSON { [self] response in
            switch response.result {
            case .success(let value) :
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
                    let decoder = JSONDecoder()
                    do {
                        let music = try decoder.decode(Music.self, from: data)
                        self.setMusic(music: music)
                    } catch {
                        print(error)
                    }
                } catch {
                    print(error)
                }
                
            case .failure(let e) : print("error : \(String(e.localizedDescription))")
            }
        }
    }
    
    func setMusic(music:Music){
        singer.text = music.singer
        musicTitle.text = music.title
        totalTime = music.duration!
        slider.maximumValue = Float(music.duration!)
        
        let minute = totalTime/60
        let second = String(format: "%02d",totalTime - (minute*60))
        endTime.text = "\(minute):\(second)"
        
        convertLyrics(lyrics: music.lyrics!)
        
        //image
        if let imageURL = music.image {
            let url = URL(string: imageURL)
            DispatchQueue.global().async {
                let imageData = try? Data(contentsOf: url!)
                DispatchQueue.main.async {
                    self.image.image = UIImage(data: imageData!)
                }
            }
        }
        //audio
        if let fileURL = music.file {
            guard let url = URL(string: fileURL) else {
                print("error")
                return
            }
            musicPlayerManager.setUp(url)
            addPeriodicTimeObserver()
        }
    }
    
    func convertLyrics(lyrics:String){
        
        var array = lyrics.components(separatedBy: "[")
        array.removeFirst()
        for arr in array {
            
            let timeAndlyrics = arr.components(separatedBy: "]")
            
            let startTime = timeAndlyrics[0].components(separatedBy: ":")
            
            let time = Int(startTime[0])! * 60 + Int(startTime[1])!
            lyricsArray.append(Lyrics(time: time, lyric: timeAndlyrics[1]))
        }
        musicPlayerManager.lyrics = lyricsArray
    }
    
    func addPeriodicTimeObserver(){
        let time = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(1.0))
        
        timerObserverToken = musicPlayerManager.player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [self] (CMTime) -> Void in
            
            if self.musicPlayerManager.player?.currentItem?.status == .readyToPlay {
                let time : Float64 = CMTimeGetSeconds((self.musicPlayerManager.player?.currentTime())!)
                let minute = Int(time / 60)
                self.currentTime.text = "\(minute):\(String(format: "%02d", Int(time)-minute*60))"
                self.slider.value = Float(time);
                
                let index = musicPlayerManager.searchLyrics(time: Int(time))
                if musicPlayerManager.lyrics?[index].time == Int(time) {
                    lyrics.text = musicPlayerManager.lyrics?[index].lyric
                }
                
            }
        }
        
    }
    @objc func tap(sender:UITapGestureRecognizer){
        performSegue(withIdentifier: "lyricsDetail", sender: self)
    }
    
    @objc func sliderValueChanged(_ sender:UISlider!) {
        let value = sender.value
        let minute = Int(value)/60
        currentTime.text = "\(minute):\(String(format: "%02d", Int(value) - minute*60))"
        
        let targetTime = CMTimeMake(value: Int64(value), timescale: 1)
        musicPlayerManager.player?.seek(to: targetTime)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as? LyricsViewController
        destination?.duration = slider.maximumValue
        
    }
    
}
