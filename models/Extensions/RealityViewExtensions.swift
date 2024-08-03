/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App-specific extension on RealityView.
*/

import Foundation
import RealityKit
import SwiftUI

// MARK: - RealityView Extensions
public extension RealityView {
    
    /// Apply this to a `RealityView` to pass gestures on to the component code.
    func installGestures<T>(_ simultaneously: T) -> some View where T : Gesture {
        simultaneousGesture(
            SimultaneousGesture(dragGesture, magnifyGesture.simultaneously(with: rotateGesture).simultaneously(with: simultaneously)), including: .all
        )
//
//        simultaneousGesture(dragGesture)
//            .simultaneousGesture(magnifyGesture)
//            .simultaneousGesture(rotateGesture)
//            .simultaneousGesture(simultaneously)
            
    }
    
    /// Builds a drag gesture.
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .handActivationBehavior(.pinch)
            .useGestureComponent()
    }
    
    /// Builds a magnify gesture.
    var magnifyGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .handActivationBehavior(.pinch)
            .useGestureComponent()
    }
    
    /// Buildsa rotate gesture. da
    var rotateGesture: some Gesture {
        RotateGesture3D()
            .targetedToAnyEntity()
            .handActivationBehavior(.pinch)
            .useGestureComponent()
    }
}
