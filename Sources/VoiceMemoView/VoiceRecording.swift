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
    private var recorder : AVAudioRecorder?
    private var persistent = false
    
    public init(_ persistent : Bool = true ) {
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
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            self.recorder = try AVAudioRecorder(url:self.url, settings:settings)
        } catch {
            os_log("%@", log: .default, type: .error,
                   "SpeechRecording.init recorder error: \(error.localizedDescription)")
            do {
                try FileManager.default.removeItem(at: self.url)
            } catch {
                recorder = nil
            }
        }
    }

    public override func start(_ completion: ((SpeechRecording, Error?) -> Void)? = nil ) {
        if self.recorder == nil {
            do {
                let settings = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 12000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                self.recorder = try AVAudioRecorder(url:self.url, settings:settings)
            } catch {
                if let comp = completion {
                    comp(self, error)
                }
            }
        }
        if let record = self.recorder {
            if !record.isRecording {
                record.record()
                self.isRecording = true
                self.isPaused = false
            }
        }
    }
    public override func stop() {
        if self.isRecording {
            if let record = self.recorder {
                record.stop()
            }
            self.isRecording = false
            self.isPaused = false
        }
    }
    public override func pause() {
        if self.isRecording {
            if let record = self.recorder {
                record.pause()
                self.isPaused = true
            }
        }
    }

    
    public func transcribe(url: URL, completion: @escaping (SpeechRecording,Error?) ->Void) {
        if let rec = SpeechModel.shared.recognizer {
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            rec.recognitionTask(with: request) { result, error in
                if let err = error {
                    completion(self, err)
                } else if let result = result {
                    self.transcription = result.bestTranscription.formattedString
                    self.segments.removeAll()
                    for seg in result.bestTranscription.segments {
                        self.segments.append( seg.substring )
                    }
                }
            }
        }
    }

}
