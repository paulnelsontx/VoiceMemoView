//
//  VoiceMemoView.swift
//  Gas Tripper
//
//  Created by Paul Nelson on 8/13/21.
//  Copyright © 2021 Paul W. Nelson, Nelson Logic. All rights reserved.
//

import SwiftUI
import Speech
import os


public struct VoiceMemoView : View {
    @ObservedObject public var recorder : SpeechRecording
    @ObservedObject public var model = SpeechModel.shared
    @State private var showEnableSpeech = false
    @State private var otherInUse = false
    @State private var alertInfo : AlertInfo?
    @State private var labelColor : Color = Color.red
    @State private var labelImageName = "mic.fill"
    @State private var pushState = false
    var pushGesture : some Gesture {
        DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
            .onChanged { _ in
                if self.pushState == false {
                    self.startRecording()
                }
                self.pushState = true
            }
            .onEnded { didEnd in
                self.pushState = false
                recorder.stop()
            }
    }
    
    public init(recorder: SpeechRecording) {
        self.recorder = recorder
        if !model.available {
            labelColor = .gray
        }
    }
    
    private struct AlertInfo : Identifiable {
        var title : Text
        var message : Text
        var primary : Alert.Button?
        var secondary : Alert.Button?
        var dismiss : Alert.Button
        var id : String
        
        init( title: String, message: String) {
            self.id = title + message
            self.title = Text(title)
            self.message = Text(message)
            self.dismiss = .default(Text("BUTTON_OK"))
        }
    }
    
    public var body: some View {
        HStack {
            VStack {
                if recorder.pushToTalk, recorder.isRecording {
                    Text(recorder.pushToTalkLabel).font(.title)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
                HStack {
                    if self.otherInUse {
                        Image(systemName:"mic.fill").foregroundColor(.gray)
                    } else if recorder.pushToTalk, model.available {
                        Image(systemName:labelImageName).foregroundColor(labelColor)
                            .gesture(pushGesture)
                    } else {
                        Button(action: {recording(tap: true)}, label: {
                            Label("", systemImage: labelImageName).foregroundColor(labelColor)
                                .labelStyle(IconOnlyLabelStyle())
                        })
                    }
                    if recorder.canPlay {
                        Button(action: playback, label: {
                            if recorder.isPlaying {
                                Label("", systemImage: "stop.circle")
                                    .labelStyle(IconOnlyLabelStyle())
                            } else {
                                Label("", systemImage: "play.fill")
                                    .labelStyle(IconOnlyLabelStyle())
                            }
                        })
                        .padding(.leading,20)
                        .disabled(otherInUse)
                    }
                }
            }
        }
        .onReceive(SpeechModel.shared.$activeRecorder, perform: { recorder in
            self.otherInUse = (recorder != nil && recorder != self.recorder)
        })
        .onReceive(recorder.$isRecording) { isRecording in
            labelImageName = isRecording ? "stop.circle" : "mic.fill"
        }
        .alert(item: $alertInfo, content: { info in
            if let primary = info.primary, let secondary = info.secondary {
                return Alert(title: info.title, message: info.message,
                      primaryButton: primary,
                      secondaryButton: secondary)
            } else {
                return Alert(title: info.title, message: info.message, dismissButton: info.dismiss)
            }
        })
    }
    
    private func openSettings() {
        let settings = URL(string: UIApplication.openSettingsURLString)
        if let url = settings {
            UIApplication.shared.open(url, options: [:]) { launched in
                os_log("%@", log: .default, type: .debug,
                       "VoiceMemoView launched settings app")
            }
        }
    }
    
    private func startRecording() {
        if model.available{
            if !recorder.isRecording {
                recorder.record()
            } else {
                os_log("%@", log: .default, type: .debug,
                       "error: push to talk already recording")
            }
        }
    }
    
    private func playback() {
        if recorder.canPlay, !recorder.isPlaying {
            recorder.play()
        } else {
            recorder.stop()
        }
    }
    
    private func recording(tap: Bool) {
        if model.available{
            if recorder.isRecording {
                os_log("%@", log: .default, type: .debug,
                       "VoiceMemoView stopping recorder")
                recorder.stop()
                
            } else {
                os_log("%@", log: .default, type: .debug,
                       "VoiceMemoView starting recorder")
                recorder.record()
            }
        } else {
            withAnimation {
                self.showEnableSpeech = true
                let title = Bundle.module.localizedString(forKey: "SPEECH_DISABLED_ALERT_TITLE", value: "xx No Location", table: nil)
                let message = Bundle.module.localizedString(forKey: "SPEECH_DISABLED_ALERT_MESSAGE", value: "xx No Location", table: nil)
                let primary = Bundle.module.localizedString(forKey: "SPEECH_DISABLED_ALERT_OPEN", value: "xx Change", table: nil)
                let secondary = Bundle.module.localizedString(forKey: "SPEECH_BUTTON_CANCEL", value: "xx Cancel", table: nil)
                var info = AlertInfo(title: title, message: message)
                info.primary = .default(Text(primary), action: openSettings)
                info.secondary = .default(Text(secondary))
                alertInfo = info
            }
        }
    }
}

#if DEBUG
struct VoiceMemoView_Previews : PreviewProvider {
    static var previews: some View {
        VoiceMemoView(recorder: SpeechDictation())
    }
}
#endif
