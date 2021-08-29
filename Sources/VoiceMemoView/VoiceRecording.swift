//
//  SpeechRecording.swift
//  Gas Tripper
//
//  Created by Paul Nelson on 8/13/21.
//  Copyright © 2021 Paul W. Nelson, Nelson Logic. All rights reserved.
//

import Foundation
import Speech
import os

public class VoiceRecording : SpeechRecording {
    public let uuid : UUID
    public let url : URL
    private var recognizer : SFSpeechRecognizer?
    private var recorder : Recorder?
    private var player : Player?
    private var persistent = false
    
    public var content : Data? {
        return FileManager.default.contents(atPath: url.path)
    }
    
    class Recorder : NSObject, AVAudioRecorderDelegate {
        public var recorder : AVAudioRecorder
        public var parent : VoiceRecording
        
        init(parent: VoiceRecording, rate: Int = 12000) throws {
            self.parent = parent
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: rate,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            do {
                self.recorder = try AVAudioRecorder(url:parent.url, settings:settings)
            } catch {
                parent.error = error
                os_log("%@", log: .default, type: .error,
                       "SpeechRecording.init recorder error: \(error.localizedDescription)")
                do {
                    try FileManager.default.removeItem(at: parent.url)
                } catch {
                }
                throw error
            }
            super.init()
            self.recorder.delegate = self
        }
        func stop() {
            self.recorder.stop()
            parent.recorderDidFinishRecording(successfully: true)
        }
        func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                             successfully flag: Bool) {
            parent.recorderDidFinishRecording(successfully: flag)
        }
        func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                              error: Error?) {
            parent.recorderDidFinishRecording(successfully: false)
        }
    }
    
    class Player : NSObject, AVAudioPlayerDelegate {
        public var player : AVAudioPlayer
        public var parent : VoiceRecording
        var isPlaying : Bool {player.isPlaying}
        init(parent: VoiceRecording) throws {
            self.parent = parent
            self.player = try AVAudioPlayer(contentsOf:parent.url)
            super.init()
            self.player.delegate = self
        }
        public func play() -> Bool {
            var result = false
            if player.prepareToPlay() {
                result = player.play()
            }
            return result
        }
        
        public func stop() {
            player.stop()
        }
        
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer,
                                         successfully flag: Bool) {
            parent.didFinishPlaying(successfully: flag)
        }
        func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer,
                                            error: Error?) {
            parent.didFinishPlaying(successfully: false)
        }
    }
    
    public init( content: Data? = nil, _ persistent : Bool = false ) {
        self.uuid = UUID()
        var folder : URL?
        if persistent {
            let folders = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            folder = folders.first
            self.persistent = persistent
        }
        if folder == nil {
            folder = FileManager.default.temporaryDirectory
            self.persistent = false
        }
        self.url = URL(fileURLWithPath: "av_\(self.uuid.uuidString).m4a", relativeTo: folder!)
        super.init()
        if let contents = content {
            self.canPlay = FileManager.default.createFile(atPath: self.url.path,
                                           contents: contents,
                                           attributes: [FileAttributeKey.posixPermissions:NSNumber(value:0x1a4)])
        }
        do {
            let rec = try Recorder(parent:self)
            self.recorder = rec
            rec.parent = self
        } catch {
            self.error = error
            os_log("%@", log: .default, type: .error,
                   "SpeechRecording.init recorder error: \(error.localizedDescription)")
            do {
                try FileManager.default.removeItem(at: self.url)
            } catch {
                recorder = nil
            }
        }
    }
    
    deinit {
        do {
            try FileManager.default.removeItem(at: self.url)
        } catch {
            recorder = nil
        }
    }

    public override func record() {
        if !configureSession() {
            return
        }
        self.canPlay = false
        if self.recorder == nil {
            do {
                let rec = try Recorder(parent:self)
                rec.parent = self
                self.recorder = rec
                
            } catch {
                self.error = error
            }
        }
        if let record = self.recorder {
            if !record.recorder.isRecording {
                record.recorder.record()
                self.isRecording = true
                self.isPaused = false
            }
        }
    }
    public override func stop() {
        if self.isRecording {
            if let record = self.recorder {
                record.stop()
                // canPlay is set by a delegate callback
            }
            recorder = nil
        } else if let play = self.player, play.isPlaying {
            play.stop()
            player = nil
        }
        super.stop()
    }
    public override func pause() {
        if self.isRecording {
            if let record = self.recorder {
                record.recorder.pause()
                self.isPaused = true
            }
        }
    }
    
    @discardableResult override public func play() -> Bool {
        if self.isRecording {
            stop()
        }
        if !configureSession() {
            return false
        }
        if super.play() == false {
            return false
        }
        do {
            let play = try Player(parent:self)
            play.parent = self
            self.player = play
            self.isPlaying = play.play()
            return self.isPlaying
        } catch {
            self.error = error
        }
        return false
    }
    
    public func delete() {
        do {
            try FileManager.default.removeItem(at: self.url)
        } catch {
            recorder = nil
        }
    }
    
    public func didFinishPlaying(successfully: Bool) {
        self.canPlay = successfully
        self.isPlaying = false
        self.player = nil
        super.stop()
    }
    
    public func recorderDidFinishRecording(successfully flag: Bool) {
        if self.isRecording {
            self.isRecording = false
            self.canPlay = flag
            self.recorder = nil
        }
    }

    public func transcribe(completion: ((SpeechRecording,Error?) ->Void)? = nil) {
        if let rec = SpeechModel.shared.recognizer {
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            rec.recognitionTask(with: request) { result, error in
                if let err = error, let comp = completion {
                    comp(self, err)
                } else if let result = result {
                    self.transcription = result.bestTranscription.formattedString
                    self.segments.removeAll()
                    for seg in result.bestTranscription.segments {
                        self.segments.append( seg.substring )
                    }
                    if let comp = completion {
                        comp(self, nil)
                    }
                }
            }
        }
    }

}
