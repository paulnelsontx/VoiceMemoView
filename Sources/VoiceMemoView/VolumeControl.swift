//
//  File.swift
//  
//
//  Created by Paul Nelson on 8/18/21.
//

import SwiftUI
import MediaPlayer
import os

struct VolumeControl : UIViewRepresentable {
    typealias UIViewType = MPVolumeView
    
    func makeUIView(context: Context) -> MPVolumeView {
        return MPVolumeView(frame: CGRect.zero)
    }
    
    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        uiView.setNeedsLayout()
    }
    
    static func dismantleUIView(_ uiView: MPVolumeView, coordinator: ()) {
        os_log("%@", log: .default, type: .error,
               "VolumeControl dismantleUIView" )
    }
}
