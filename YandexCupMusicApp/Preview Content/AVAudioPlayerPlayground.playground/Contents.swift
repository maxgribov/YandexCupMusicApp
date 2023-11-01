import Foundation
import AVFoundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

func makePlayer(fileName: String, volume: Float = 1.0, rate: Float = 1.0) throws -> AVAudioPlayer {
    
    guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
        throw NSError(domain: "playground", code: 1)
    }
    
    let data = try Data(contentsOf: fileURL)
    let player = try AVAudioPlayer(data: data)
    player.numberOfLoops = -1
    player.volume = volume
    player.enableRate = true
    player.rate = rate
    
    return player
}

let player1 = try? makePlayer(fileName: "guitar_01", volume: 0.5)
player1?.play()


// simulate player created later
let player2 = try? makePlayer(fileName: "brass_01", rate: 1.0)

// sync playback of two samples
DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
    
    print(player1!.deviceCurrentTime, player1!.currentTime, player1!.duration)
    
    // just start playing with delay
//    player2?.play(atTime: player1!.deviceCurrentTime + player1!.currentTime)
    
    // not ideally but it works
    player2?.currentTime = player1!.currentTime
    player2?.play()
}
