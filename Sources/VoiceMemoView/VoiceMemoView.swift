//
//  VoiceMemoView.swift
//  Gas Tripper
//
//  Created by Paul Nelson on 8/13/21.
//  Copyright © 2021 Paul W. Nelson, Nelson Logic. All rights reserved.
//

import SwiftUI
import Speech


public struct VoiceMemoView : View {
    @ObservedObject public var recorder : SpeechRecording
    @ObservedObject public var model = SpeechModel.shared
    @State private var showEnableSpeech = false
    @State private var alertInfo : AlertInfo?
    
    public init(recorder: SpeechRecording) {
        self.recorder = recorder
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
//                    ZStack(alignment: .center) {
//                        RoundedRectangle(cornerRadius: 14).foregroundColor(.white)
//                            .frame(minWidth:100, maxHeight:88)
//                        Text(recorder.pushToTalkLabel).font(.title)
//                            .padding(5)
//                            .background(Color.white)
//                            .foregroundColor(.black)
//                            .clipShape(Capsule())
//                    }
                    Text(recorder.pushToTalkLabel).font(.title)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
                Button(action: {recording(tap: true)}, label: {
                    if recorder.pushToTalk, recorder.isRecording {
                        VStack {
                            Label("", systemImage: "mic.fill").foregroundColor(model.available ? .red : .gray)
                                .labelStyle(IconOnlyLabelStyle())
                                .font( .largeTitle)
                        }
                    }
                    else if recorder.isRecording {
                        Label("", systemImage: "stop.circle").foregroundColor(.red)
                            .labelStyle(IconOnlyLabelStyle())
                    } else {
                        Label("", systemImage: "mic.fill").foregroundColor(model.available ? .red : .gray)
                            .labelStyle(IconOnlyLabelStyle())
                    }
                })
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.05).onEnded { _ in
                    if recorder.pushToTalk {
                        startRecording()
                    }
                })
            }
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
                print("launched settings app \(launched)")
            }
        }
    }
    
    private func startRecording() {
        if model.available{
            if !recorder.isRecording {
                recorder.start()
            } else {
                print("error: push to talk already recording")
            }
        }
    }
    
    private func recording(tap: Bool) {
        print("recording \(recorder.isRecording) tap:\(tap)")
        if model.available{
            if recorder.isRecording {
                print("stopping recorder")
                recorder.stop()
            } else {
                print("starting recorder")
                recorder.start()
            }
        } else {
            withAnimation {
                self.showEnableSpeech = true
                let title = Bundle.module.localizedString(forKey: "SPEECH_DISABLED_ALERT_TITLE", value: "xx No Location", table: nil)
                let message = Bundle.module.localizedString(forKey: "SPEECH_DISABLED_ALERT_MESSAGE", value: "xx No Location", table: nil)

                var info = AlertInfo(title: title, message: message)
                info.primary = .default(Text("SPEECH_DISABLED_ALERT_OPEN"), action: openSettings)
                info.secondary = .default(Text("BUTTON_CANCEL"))
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
