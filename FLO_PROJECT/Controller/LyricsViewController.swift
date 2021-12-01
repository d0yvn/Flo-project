//
//  LyricsViewController.swift
//  FLO_PROJECT
//
//  Created by doyun on 2021/11/13.
//

import UIKit
import AVFoundation

class LyricsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var endTime: UILabel!
    
    var duration : Float = 0
    var timeObserver : Any?
    var index = 0
    
    let musicPlayerManager = MusicPlayerManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    
        slider.maximumValue = duration
        endTime.text = "\(duration/60):\(String(format: "%02d", (Int(duration) - Int(duration/60)*60)))"
        
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        addPeriodicTimeObserver()
        musicPlayerManager.player?.rate == 0 ? button.setImage(UIImage(systemName: "play.fill"), for: .normal) : button.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        
        // Do any additional setup after loading the view.
    }
    
    func addPeriodicTimeObserver(){

        let time = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(1.0))
        musicPlayerManager.player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [self] (CMTime) -> Void in
            if self.musicPlayerManager.player?.currentItem?.status == .readyToPlay {
                let time = CMTimeGetSeconds((self.musicPlayerManager.player?.currentTime())!)
                let nextIndex = musicPlayerManager.searchLyrics(time: Int(time))
                self.updateTime(Int(time))
                if nextIndex != index {
                    self.updateLyricsTableView(willUpdateIndex: nextIndex)
                    self.index = nextIndex
                }
                
            }
        }
    }

    @IBAction func pressedButton(_ sender: UIButton) {
        if musicPlayerManager.player?.rate == 0 {
            button.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            musicPlayerManager.player?.play()
        } else {
            button.setImage(UIImage(systemName: "play.fill"), for: .normal)
            musicPlayerManager.player?.pause()
        }
    }
    
    func updateTime(_ time:Int){
        let minute = Int(time / 60)
        currentTime.text = "\(minute):\(String(format: "%02d", Int(time)-minute*60))"
        slider.value = Float(time)
    }
    @objc func sliderValueChanged(_ sender:UISlider!) {
        let value = sender.value
        let minute = Int(value)/60
        currentTime.text = "\(minute):\(String(format: "%02d", Int(value) - minute*60))"
        
        let targetTime = CMTimeMake(value: Int64(value), timescale: 1)
        musicPlayerManager.player?.seek(to: targetTime)
    }
}

extension LyricsViewController : UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicPlayerManager.lyrics!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LyricsCell", for: indexPath) as? LyricsTableViewCell else {
            return UITableViewCell()
        }
        
        cell.label.text = musicPlayerManager.lyrics?[indexPath.row].lyric
        cell.label.textColor = .gray
        return cell
    }
    
    func updateLyricsTableView(willUpdateIndex index:Int) {
        let prev = musicPlayerManager.index
        
        let indexPath = IndexPath(row: index, section: 0)
        
        if let cell = tableView.cellForRow(at: indexPath) as? LyricsTableViewCell {
            cell.label.textColor = .black
        }
        
        guard prev >= 0 else { return }
        
        if let prevCell = tableView.cellForRow(at: IndexPath(row: prev, section: 0)) as? LyricsTableViewCell{
            prevCell.label.textColor = .gray
        }
        
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        musicPlayerManager.index = index
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let row = indexPath.row
        
        if let lyrics = musicPlayerManager.lyrics?[row] {
            let targetTime = CMTimeMake(value: Int64(lyrics.time), timescale: 1)
            updateLyricsTableView(willUpdateIndex: row)
            musicPlayerManager.player?.seek(to: targetTime)

            updateTime(lyrics.time)
        }
        
    }
    
}
