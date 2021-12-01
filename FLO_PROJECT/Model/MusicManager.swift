//
//  MusicManager.swift
//  FLO_PROJECT
//
//  Created by doyun on 2021/11/12.
//

import Foundation
import Alamofire

protocol MusicManagerDelegate {
    func didUpdateMusic(_ musicManager:MusicManager, music:Music)
    func didFailWithError(error : Error)
}
struct MusicManager{
    
    var delegate : MusicManagerDelegate?
    
    func callAPI() {
        
        let url = "https://grepp-programmers-challenges.s3.ap-northeast-2.amazonaws.com/2020-flo/song.json"
        AF.request(url).validate(statusCode: 200..<300).responseJSON { response in
            switch response.result {
            case .success(let value) :
                do {
                    let data = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
                    if let music = self.parseJson(musicData: data) {
                        self.delegate?.didUpdateMusic(self,music:music)
                    }
                } catch {
                    print(error)
                }
                
            case .failure(let e) : print("error : \(String(e.localizedDescription))")
            }
            
        }
    }
    
    func parseJson(musicData : Data) -> Music? {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(Music.self, from: musicData)
            return decodedData
        } catch {
            self.delegate?.didFailWithError(error : error)
            print(error)
            return nil
        }
    }
}


