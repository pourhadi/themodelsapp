//
//  Gloves.swift
//  models
//
//  Created by Daniel Pourhadi on 3/20/24.
//

import SwiftUI
import ARKit
import RealityKit
import RealityKitContent



struct SpaceGloves2: View {

    let arSession = ARKitSession()
    let handTracking = HandTrackingProvider()

    @State var leftHand: ModelEntity?
    @State var rightHand: ModelEntity?
    
    var body: some View {

        RealityView { content in

            let root = Entity()
            content.add(root)

            let lHand = try! await Entity.init(named: "left", in: realityKitContentBundle)
            let rHand = try! await Entity.init(named: "right", in: realityKitContentBundle)
            
//            let left = hands.findEntity(named: "Left_Hand")
//            leftHand = left?.findEntity(named: "skin1") as? ModelEntity
//            
//            let right = hands.findEntity(named: "Right_Hand")
//            rightHand = right?.findEntity(named: "skin0") as? ModelEntity
            // Load Left glove
//            let leftGlove = try! await ModelEntity.init(named: "leftHand", in: realityKitContentBundle)
            root.addChild(lHand)
            root.addChild(rHand)
            
//            let glove = try! await Entity.init(named: "glove2", in: realityKitContentBundle)
            leftHand = lHand.findEntity(named: "Main") as? ModelEntity
            rightHand = rHand.findEntity(named: "Main") as? ModelEntity
            
//
//            leftHand = leftGlove
//            // Load Right glove
//            let rightGlove = try! await ModelEntity.init(named: "rightHand", in: realityKitContentBundle)
//            root.addChild(rightGlove)
//            rightHand = rightGlove
            // Start ARKit session and fetch anchorUpdates
            Task {
                do {
                    try await arSession.run([handTracking])
                } catch let error {
                    print("Encountered an unexpected error: \(error.localizedDescription)")
                }
                for await anchorUpdate in handTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    switch anchor.chirality {
                    case .left:
                        if let leftGlove = leftHand, let skeleton = anchor.handSkeleton {
                            leftGlove.setTransformMatrix(anchor.originFromAnchorTransform, relativeTo: nil)
//                            leftGlove.transform = Transform(matrix: anchor.originFromAnchorTransform)
                            for (index, joint) in skeleton.allJoints.enumerated() {
                                leftGlove.jointTransforms[index].rotation = simd_quatf(skeleton.joint(joint.name).parentFromJointTransform)
                            }
                        }
                    case .right:
                        if let rightGlove = rightHand, let skeleton = anchor.handSkeleton {
                            rightGlove.transform = Transform(matrix: anchor.originFromAnchorTransform)
                            for (index, joint) in skeleton.allJoints.enumerated() {
                                rightGlove.jointTransforms[index].rotation = simd_quatf(skeleton.joint(joint.name).parentFromJointTransform)

                            }
                        }
                    }
                }
            }
        }
    }
    
//    func jointName(for joint: HandSkeleton.Joint) -> String {
//        
//        switch joint.name {
//        case .
//        }
//        
//    }
}

//#Preview {
//    Gloves()
//}
