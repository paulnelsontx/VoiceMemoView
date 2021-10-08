//
//  File.swift
//  
//
//  Created by Paul Nelson on 8/18/21.
//

import SwiftUI
import MediaPlayer
import os

public struct VolumeControl : UIViewRepresentable {
    public typealias UIViewType = MPVolumeView
    
    public func makeUIView(context: Context) -> MPVolumeView {
        return MPVolumeView(frame: CGRect.zero)
    }
    
    public func updateUIView(_ uiView: MPVolumeView, context: Context) {
        uiView.setNeedsLayout()
    }
    
    public static func dismantleUIView(_ uiView: MPVolumeView, coordinator: ()) {
        os_log("%@", log: .default, type: .error,
               "VolumeControl dismantleUIView" )
    }
}
