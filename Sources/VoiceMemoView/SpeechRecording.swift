//
//  SpeechRecording.swift
//  Gas Tripper
//
//  Created by Paul Nelson on 8/13/21.
//  Copyright © 2021 Paul W. Nelson, Nelson Logic. All rights reserved.
//

import SwiftUI
import Speech
import os

public struct SpeechError : Error {
    var localizedDescription: String
    
    init(_ desc: String ) {
        self.localizedDescription = desc
    }
}

public class SpeechRecording : NSObject, ObservableObject {
    public var pushToTalk : Bool
    public var pushToTalkLabel : LocalizedStringKey = "SPEECHRECORD_PUSH_TO_TALK_LABEL"
    @Published var isRecording = false
    @Published var isPaused = false
    public var session : AVAudioSession?
    @Published var transcription : String = ""
    @Published var segments = [String]()
    
    public init( pushToTalk: Bool = false) {
        self.pushToTalk = pushToTalk
    }
    
    public func configureSession() -> Bool {
        if session != nil {
            return true
        }
        let sess = AVAudioSession.sharedInstance()
        do {
            try sess.setCategory(.record, mode: .measurement, options: .mixWithOthers)
            try sess.setActive(true, options: .notifyOthersOnDeactivation)
            self.session = sess
        } catch {
            os_log("%@", log: .default, type: .error,
                   "SpeechRecording.configureSession session error: \(error.localizedDescription)" )
            self.session = nil
        }
        return self.session != nil
    }
    
    public func start(_ completion: ((SpeechRecording, Error?) -> Void)? = nil ) {
        if let complete = completion {
            complete(self, SpeechError("Invalid subclass"))
        }
    }
    
    public func stop() {
        if let sess = session {
            do {
                try sess.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                os_log("%@", log: .default, type: .error,
                       "SpeechRecording.stop setActive error: \(error.localizedDescription)" )
            }
        }
    }
    
    public func pause() {
        
    }
}
