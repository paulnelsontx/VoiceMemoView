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

public struct SpeechError : Error {
    var localizedDescription: String
    
    init(_ desc: String ) {
        self.localizedDescription = desc
    }
}

public class SpeechRecording : NSObject, ObservableObject {
    public var pushToTalk : Bool
    public var pushToTalkLabel : String
    @Published public var isRecording = false
    @Published public var isPlaying = false
    @Published public var isPaused = false
    @Published public var canPlay = false
    @Published public var error: Error?
    public var session : AVAudioSession?
    @Published public var transcription : String = ""
    @Published public var segments = [String]()
    
    private var observing : NSObjectProtocol?
    
    public init( pushToTalk: Bool = false) {
        self.pushToTalk = pushToTalk
        self.pushToTalkLabel = Bundle.module.localizedString(forKey: "SPEECHRECORD_PUSH_TO_TALK_LABEL", value: "xx push to talk", table: nil)
    }
    
    public func configureSession() -> Bool {
        if SpeechModel.shared.setActive(self) == false {
            return false
        }
        if session != nil {
            return true
        }
        let sess = AVAudioSession.sharedInstance()
        do {
            try sess.setCategory(.playAndRecord, mode: .default, options: [.duckOthers,
                                                                           .interruptSpokenAudioAndMixWithOthers,
                                                                           .defaultToSpeaker])
            try sess.setActive(true, options: .notifyOthersOnDeactivation)
            if let _ = sess.availableModes.firstIndex(of: .spokenAudio) {
                do {
                    try sess.setMode(.spokenAudio)
                } catch { }
            }
            self.session = sess
            self.observing =
                NotificationCenter.default.addObserver(
                    forName: AVAudioSession.interruptionNotification,
                    object: AVAudioSession.sharedInstance,
                    queue: OperationQueue.main) { notification in
                        self.processNotification(notification)
                    }
        } catch {
            self.error = error
            os_log("%@", log: .default, type: .error,
                   "SpeechRecording.configureSession session error: \(error.localizedDescription)" )
            self.session = nil
            SpeechModel.shared.resetActive(self)
        }
        return self.session != nil
    }

    @objc func processNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        os_log("%@", log: .default, type: .debug,
               "SpeechRecording handleInterruptions: type: \(type), \(userInfo)")
        if type == .began {
            interruptionBegan()
        } else if type == .ended {
            interruptionEnded()
        }
    }
    
    public func record() {
    }
    
    public func stop() {
        if let sess = session {
            do {
                isRecording = false
                isPlaying = false
                self.isPaused = false
                try sess.setActive(false, options: .notifyOthersOnDeactivation)
                SpeechModel.shared.resetActive(self)
                if let observer = self.observing {
                    NotificationCenter.default.removeObserver(observer)
                }
            } catch {
                self.error = error
                os_log("%@", log: .default, type: .error,
                       "SpeechRecording.stop setActive error: \(error.localizedDescription)" )
            }
        }
    }
    
    public func pause() {
    }
    
    @discardableResult public func play() -> Bool {
        if self.configureSession(), let sess = session {
            do {
                try sess.setActive(true, options:.notifyOthersOnDeactivation)
                return true
            } catch {
                self.error = error
                os_log("%@", log: .default, type: .error,
                       "SpeechRecording.play setActive error: \(error.localizedDescription)" )
            }
        }
        return false
    }
    
    func interruptionBegan() {
        stop()
    }
    func interruptionEnded() {
        
    }

    public func reset() {
        stop()
        session = nil
        self.error = nil
        isPaused = false
        isRecording = false
        isPlaying = false
        canPlay = false
        self.segments.removeAll()
        self.transcription = ""
    }
}
