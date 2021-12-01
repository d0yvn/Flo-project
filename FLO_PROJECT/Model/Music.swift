import Foundation
import UIKit


struct Music : Codable {
    let singer : String?
    let album : String?
    let title : String?
    let duration : Int?
    let image : String?
    let file : String?
    let lyrics : String?
}

struct Lyrics {
    let time : Int
    let lyric : String
}
