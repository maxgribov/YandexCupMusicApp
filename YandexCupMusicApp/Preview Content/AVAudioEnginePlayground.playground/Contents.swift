import AVFoundation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

func url(aifFileName: String) throws -> URL {
    
    guard let fileURL = Bundle.main.url(forResource: aifFileName, withExtension: "aif") else {
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
    
    init(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
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

let audioSession = AVAudioSession.sharedInstance()
try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

let player1 = AVAudioPlayerNode()
let player2 = AVAudioPlayerNode()

let engine = AVAudioEngine()
engine.attach(player1)
engine.attach(player2)
engine.connect(player1, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
engine.connect(player2, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
try engine.start()

let guitarFile = try makeFile(fileName: "guitar_01")
let drumsFile = try makeFile(fileName: "drums_01")

let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)
format == guitarFile.processingFormat
//print(format)

player1.scheduleBuffer(try makeFileBuffer(file: guitarFile), at: nil, options: .loops)
//player2.scheduleBuffer(try makeFileBuffer(file: drumsFile), at: nil, options: .loops)

let settings = ["AVLinearPCMIsBigEndianKey": 0, 
                "AVSampleRateKey": 44100,
                "AVNumberOfChannelsKey": 2,
                "AVLinearPCMIsNonInterleaved": 1,
                "AVFormatIDKey": 1819304813,
                "AVLinearPCMIsFloatKey": 1,
                "AVLinearPCMBitDepthKey": 32]

let format1 = AVAudioFormat(settings: settings)!

let guitarUncompressedData = try Data(contentsOf: url(aifFileName: "guitar_01"))
let file = try AVAudioFile(forReading: url(aifFileName: "guitar_01"))
print(file.processingFormat.settings["AVChannelLayoutKey"])

/// Terrible noise, no audio

let bufferFromData = guitarUncompressedData.makeCompressedBuffer(format: file.processingFormat)

/// it does not schedule compressed buffer!!!
//player2.scheduleBuffer(bufferFromData, at: nil, options: .loops)


/// Terrible noise, no audio too :(
/*
let nsData = NSData(data: drumsFileData)
let bufferFromData = nsData.toPCMBuffer(format: format!)
player2.scheduleBuffer(bufferFromData!, at: nil, options: .loops)
 */

//player1.play()
player2.play()

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
