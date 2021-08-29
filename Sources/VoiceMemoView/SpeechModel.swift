//
//  SpeechModel.swift
//  Gas Tripper
//
//  Created by Paul Nelson on 8/13/21.
//  Copyright © 2021 Paul W. Nelson, Nelson Logic. All rights reserved.
//

import Foundation
import Speech
import os

public struct SpeechRecord : Codable {
    public var url : URL
    public var time : Date
}

public class SpeechModel : NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    public var recognizer : SFSpeechRecognizer?
    public static var shared : SpeechModel {
        if _speechModel == nil {
            _speechModel = SpeechModel()
        }
        return _speechModel!
    }
    @Published public var available = false
    @Published public var activeRecorder : SpeechRecording?
    public func setActive(_ recording: SpeechRecording) -> Bool {
        if activeRecorder == nil {
            activeRecorder = recording
        }
        return activeRecorder === recording
    }
    public func resetActive(_ recording: SpeechRecording) {
        if activeRecorder === recording {
            activeRecorder = nil
        }
    }
//    @Published var recordings = [SpeechRecord]()
//    private var currentRecording : URL?
    public var queue : OperationQueue
    
    private var audioRecorder : AVAudioRecorder?
    private static var _speechModel : SpeechModel? = nil

    public override init() {
        self.queue = OperationQueue()
        self.queue.qualityOfService = .background
        super.init()
        self.recognizer = SFSpeechRecognizer()
        if let rec = self.recognizer {
            rec.delegate = self
        }
        SFSpeechRecognizer.requestAuthorization { [unowned self] authStatus in
            os_log("%@", log: .default, type: .error, "SpeechModel.init authorization \(authStatus)")
            DispatchQueue.main.async {
                self.available = authStatus == .authorized
            }
        }
    }
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer,
                          availabilityDidChange available: Bool) {
        self.available = available
    }

}
