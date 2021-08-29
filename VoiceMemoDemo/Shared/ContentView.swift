//
//  ContentView.swift
//  Shared
//
//  Created by Paul Nelson on 8/18/21.
//

import SwiftUI
import VoiceMemoView

struct ContentView: View {
    @ObservedObject var voiceRecording = VoiceRecording()
    @ObservedObject var dictation = SpeechDictation(pushToTalk: true)
    var body: some View {
        VStack {
            Text("VoiceMemoView Demo")
                .padding()
            Spacer()
            HStack {
                Text("Make a recording")
                VoiceMemoView(recorder: voiceRecording)
            }
            Text(voiceRecording.transcription)
            Spacer()
            HStack {
                Text("Dictate some text")
                VoiceMemoView(recorder:dictation)
            }
            Text(dictation.transcription)
            Spacer()
        }
        .onReceive(voiceRecording.$canPlay) { canPlay in
            if canPlay {
                voiceRecording.transcribe()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
