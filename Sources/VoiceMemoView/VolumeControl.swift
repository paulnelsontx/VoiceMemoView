//
//  File.swift
//  
//
//  Created by Paul Nelson on 8/18/21.
//

import SwiftUI
import MediaPlayer
import os

public struct VolumeSlider : UIViewRepresentable {
    public typealias UIViewType = MPVolumeView
    
    public func makeUIView(context: Context) -> MPVolumeView {
        let result = MPVolumeView(frame: CGRect.zero)
        return result
    }
    
    public func updateUIView(_ uiView: MPVolumeView, context: Context) {
        // eliminate deprecated routing button from the layout because it makes the slider
        // appear off center
        for subview in uiView.subviews {
            if let routeButton = subview as? UIButton {
                var frame = routeButton.frame
                frame.size.width = 0
                routeButton.frame = frame
            }
        }
        uiView.setNeedsLayout()
    }
    
    public static func dismantleUIView(_ uiView: MPVolumeView, coordinator: ()) {
        os_log("%@", log: .default, type: .error,
               "VolumeControl dismantleUIView" )
    }
    
    public init() {
    }
}

public struct VolumeControl : View {
    
    public var body: some View {
        HStack(alignment: .center, spacing: 10.0) {
            Label("", systemImage:"speaker.wave.1")
            VolumeSlider().frame(maxHeight:20.0)
            Label("", systemImage:"speaker.wave.3")
        }.padding(20)
    }
    
    public init() {
    }
}

struct VolumeControl_Previews: PreviewProvider {
    static var previews: some View {
        VolumeControl()
    }
}
