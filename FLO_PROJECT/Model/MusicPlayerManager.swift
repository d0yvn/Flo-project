import Foundation
import AVFoundation

final class MusicPlayerManager {
    
    static let shared = MusicPlayerManager()
    
    private init() { }
    
    var player: AVPlayer?
    var lyrics : [Lyrics]?
    var paused: Bool = false
    var index = 0
    
    func setUp(_ URL:URL){
        let item = AVPlayerItem(url: URL)
        player = AVPlayer(playerItem: item)
    }
    
    func searchLyrics(time : Int) -> Int {
        var start = 0
        var end = lyrics!.count - 1
        
        var mid = (start + end) / 2
        
        while start <= end {
            mid = (start + end) / 2
            
            if (lyrics?[mid].time)! < time {
                start = mid + 1
            } else if (lyrics?[mid].time)! == time {
                return mid
            } else {
                end = mid-1
            }
        }
        return end < 0 ? 0 : mid
    }
}
