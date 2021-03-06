//
//  SpeechMemo.swift
//  Gas Tripper
//
//  Created by Paul Nelson on 8/13/21.
//  Copyright © 2021 Paul W. Nelson, Nelson Logic. All rights reserved.
//

import Foundation
import Speech
import os

public class SpeechDictation : SpeechRecording {
    private let audioEngine = AVAudioEngine()
    private let inputNode : AVAudioInputNode
    private var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask : SFSpeechRecognitionTask?

    public override init(pushToTalk: Bool = false) {
        self.inputNode = audioEngine.inputNode
        super.init(pushToTalk: pushToTalk)
    }
    
    public override func record() {
        if isRecording {
            return
        }
        if !configureSession() {
            return
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = request
        request.shouldReportPartialResults = true
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        if let recognizer = SpeechModel.shared.recognizer {
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                self.error = error
                if error == nil, let result = result {
                    self.transcription = result.bestTranscription.formattedString
                    self.segments.removeAll()
                    for seg in result.bestTranscription.segments {
                        self.segments.append( seg.substring )
                    }
                }
                if let task = self.recognitionTask {
                    #if DEBUG
                        var stateName : String
                        switch task.state {
                        case .starting:
                            stateName = "starting"
                        case .running:
                            stateName = "running"
                        case .finishing:
                            stateName = "finishing"
                        case .canceling:
                            stateName = "canceling"
                        case .completed:
                            stateName = "completed"
                        @unknown default:
                            stateName = "unknown"
                        }
                        os_log("%@", log: .default, type: .debug,
                               "SpeechDictation.observeValue task state is \(stateName)")
                    #endif
                    if task.state == .finishing {
//                        self.audioEngine.stop()
                    } else if task.state == .completed {
                        self.audioEngine.stop()
                        self.inputNode.removeTap(onBus: 0)
                        self.recognitionRequest = nil
                        self.recognitionTask = nil
                        self.isRecording = false
                        super.stop()
                    }
                }
            }
        }
        do {
            audioEngine.prepare()
            try audioEngine.start()
            self.isRecording = audioEngine.isRunning
        } catch {
            os_log("%@", log: .default, type: .error,
                   "SpeechDictation.start audioEngine.start failed: \(error.localizedDescription)")
            self.error = error
        }
    }

    public override func stop() {
        guard self.isRecording else { return }
        if let task = self.recognitionTask {
            task.finish()
        }
//        self.audioEngine.stop()
        // don't call completion here
        // let observeValue take care of cleanup
   }
}
