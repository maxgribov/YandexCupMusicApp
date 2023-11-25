import AVFoundation
import PlaygroundSupport
import Combine

PlaygroundPage.current.needsIndefiniteExecution = true

func url(fileName: String, ext: String = "aif") throws -> URL {
    
    guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: ext) else {
        throw NSError(domain: "playground", code: 1)
    }
    
    return fileURL
}

func makeFile(fileName: String) throws -> AVAudioFile {
    
    guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
        throw NSError(domain: "playground", code: 1)
    }
    
    return try AVAudioFile(forReading: fileURL)
}

func makeFileBuffer(file: AVAudioFile) throws -> AVAudioPCMBuffer {
    
    guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length)) else {
        throw NSError(domain: "playground", code: 2)
    }
    try file.read(into: buffer)
    
    return buffer
}

extension Data {
    
    init(buffer: AVAudioPCMBuffer) {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        self.init(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
    }

    func makePCMBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let streamDesc = format.streamDescription.pointee
        let frameCapacity = UInt32(count) / streamDesc.mBytesPerFrame
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity) else { return nil }

        buffer.frameLength = buffer.frameCapacity
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers

        withUnsafeBytes { (bufferPointer) in
            guard let addr = bufferPointer.baseAddress else { return }
            audioBuffer.mData?.copyMemory(from: addr, byteCount: Int(audioBuffer.mDataByteSize))
        }

        return buffer
    }
    
    func makeCompressedBuffer(format: AVAudioFormat) -> AVAudioCompressedBuffer {
        let streamDesc = format.streamDescription.pointee
        let frameCapacity = UInt32(count) / streamDesc.mBytesPerFrame
        let buffer = AVAudioCompressedBuffer(format: format, packetCapacity: frameCapacity)

        buffer.byteLength = buffer.byteCapacity
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers

        withUnsafeBytes { (bufferPointer) in
            guard let addr = bufferPointer.baseAddress else { return }
            audioBuffer.mData?.copyMemory(from: addr, byteCount: Int(audioBuffer.mDataByteSize))
        }

        return buffer
    }
}

extension NSData {
    
    func toPCMBuffer(format: AVAudioFormat) -> AVAudioPCMBuffer? {

        guard let PCMBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(count) / format.streamDescription.pointee.mBytesPerFrame) else {
            return nil
        }
        PCMBuffer.frameLength = PCMBuffer.frameCapacity
        let channels = UnsafeBufferPointer(start: PCMBuffer.floatChannelData, count: Int(PCMBuffer.format.channelCount))
        getBytes(UnsafeMutableRawPointer(channels[0]) , length: count)
        return PCMBuffer
    }
}

extension AVAudioPlayerNode {

    var current: TimeInterval {
        
        guard let nodeTime = lastRenderTime, let playerTime = playerTime(forNodeTime: nodeTime) else {
            return 0
        }
        
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }
}

extension AVAudioPCMBuffer {
    
    var duration: TimeInterval {
        
        TimeInterval(Double(frameLength) / format.sampleRate)
    }
}

let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

let player1 = AVAudioPlayerNode()
let player2 = AVAudioPlayerNode()
let speedControl = AVAudioUnitVarispeed()

let engine = AVAudioEngine()
engine.attach(player1)
engine.attach(player2)
engine.attach(speedControl)
//engine.connect(player1, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
engine.connect(player1, to: speedControl, format: nil)
engine.connect(speedControl, to: engine.mainMixerNode, format: nil)
//engine.connect(player2, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
try engine.start()

let guitarFile = try makeFile(fileName: "guitar_01")
let drumsFile = try makeFile(fileName: "drums_01")

let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)
format == guitarFile.processingFormat
//print(format)

let player1Buffer = try makeFileBuffer(file: drumsFile)
player1.scheduleBuffer(player1Buffer, at: nil, options: .loops)
//player2.scheduleBuffer(try makeFileBuffer(file: drumsFile), at: nil, options: .loops)

//let settings = ["AVLinearPCMIsBigEndianKey": 0, 
//                "AVSampleRateKey": 44100,
//                "AVNumberOfChannelsKey": 2,
//                "AVLinearPCMIsNonInterleaved": 1,
//                "AVFormatIDKey": 1819304813,
//                "AVLinearPCMIsFloatKey": 1,
//                "AVLinearPCMBitDepthKey": 32]
//
//let format1 = AVAudioFormat(settings: settings)!

let fileUrl = url(fileName: "guitar_01", ext: "m4a")
let guitarUncompressedData = try Data(contentsOf: fileUrl)
let file = try AVAudioFile(forReading: fileUrl)
let fileBuffer = try makeFileBuffer(file: file)
let dataFromBuffer = Data(buffer: fileBuffer)

guitarUncompressedData == dataFromBuffer

//print(file.processingFormat.settings["AVChannelLayoutKey"])
print(guitarUncompressedData.count)
print(dataFromBuffer.count)

/// Terrible noise, no audio

let bufferFromData = dataFromBuffer.makePCMBuffer(format: format!)!
//let bufferFromData = guitarUncompressedData.makePCMBuffer(format: file.fileFormat)!
//let bufferFromData = guitarUncompressedData.makeCompressedBuffer(format: file.fileFormat)

/// it does not schedule compressed buffer!!!



/// Terrible noise, no audio too :(
/*
let nsData = NSData(data: drumsFileData)
let bufferFromData = nsData.toPCMBuffer(format: format!)
player2.scheduleBuffer(bufferFromData!, at: nil, options: .loops)
 */

player1.play()
speedControl.rate = 1.0

DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
    
    engine.connect(player2, to: engine.mainMixerNode, format: nil)
    let sampleRate = player1.outputFormat(forBus: 0).sampleRate
    let delay: Double = 0
    let startTime = AVAudioTime(sampleTime: player1.lastRenderTime!.sampleTime + Int64(delay * sampleRate), atRate: sampleRate)
    
    let player1NodeTime = player1.lastRenderTime
    let player1Time = player1.playerTime(forNodeTime: player1NodeTime!)
//    let offset = AVAudioTime(sampleTime: Int64(Double(player1Time!.sampleTime) / player1Time!.sampleRate), atRate: sampleRate)
    
    let offsetTime = player1.current.truncatingRemainder(dividingBy: player1Buffer.duration)
    let offset = AVAudioTime(sampleTime: -Int64(offsetTime * sampleRate), atRate: sampleRate)

    player2.scheduleBuffer(bufferFromData, at: offset, options: .loops)
//    player2.prepare(withFrameCount: 500)
    
    print(player1.lastRenderTime!)
    print(startTime)
    print(player1.lastRenderTime!.sampleTime)
    
    player2.play()
//    player2.play()
    player2.volume = 1
}


var cancellables = Set<AnyCancellable>()

Timer.publish(every: 0.1, on: .main, in: .common)
    .autoconnect()
    .sink { _ in
    
//        print("current: \(player1.current), duration: \(player1Buffer.duration), offset: \(player1.current.truncatingRemainder(dividingBy: player1Buffer.duration))")
    }
    .store(in: &cancellables)

/// looks like it crashes if on mic available
/*
 
print("Recording started")
 
engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: engine.inputNode.outputFormat(forBus: 0)) { buffer, time in
    
    print("buffer: \(buffer)")
}

DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    
    engine.inputNode.removeTap(onBus: 0)
    print("Recording stopped")
}
*/
