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
    private static var _speechModel : SpeechModel? = nil
    public static var shared : SpeechModel {
        if _speechModel == nil {
            _speechModel = SpeechModel()
        }
        return _speechModel!
    }
    @Published var available = false
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordings = [SpeechRecord]()
    private var currentRecording : URL?
    private var audioRecorder : AVAudioRecorder?
    public var queue : OperationQueue
    
    override init() {
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
