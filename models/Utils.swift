//
//  Utils.swift
//  models
//
//  Created by Daniel Pourhadi on 3/5/24.
//

import Foundation
import SwiftUI


private struct WindowSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .init(width: 1280, height: 800)
}


extension EnvironmentValues {
    var windowSize: CGSize {
        get { self[WindowSizeKey.self] }
        set { self[WindowSizeKey.self] = newValue }
    }
}


extension View {
    func windowSize(_ windowSize: CGSize) -> some View {
        environment(\.windowSize, windowSize)
    }
}

