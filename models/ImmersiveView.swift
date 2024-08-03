//
//  ImmersiveView.swift
//  models
//
//  Created by Daniel Pourhadi on 2/28/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct TransformMovement {
    var start: AffineTransform3D?
    
    var startT: Transform?
    var current: AffineTransform3D?
    var diff: AffineTransform3D?
    var translation: Vector3D?
    var rotation: Rotation3D?
    
    var anchor: UnitPoint3D? = nil
    
    var scale: CGFloat = 1
    
    var scaleSimd: SIMD3<Float> = .one
    
    var startScale: CGFloat? = nil
    
    init(start: AffineTransform3D? = nil, current: AffineTransform3D? = nil, diff: AffineTransform3D? = nil, translation: Vector3D? = nil, rotation: Rotation3D? = nil, startT: Transform? = nil) {
        self.start = start
        self.current = current
        self.diff = diff
        self.translation = translation
        self.rotation = rotation
        self.startT = startT
    }
}

struct ImmersiveView: View {
        
    @Binding var models: [ModelData]
    
    @State var pinchStartTransform: AffineTransform3D? = nil
    
    @GestureState var pinchCurrentTransform: AffineTransform3D? = nil
    
    @State var adjustedTransform:TransformMovement? = nil
    
    @State var transform: TransformMovement = TransformMovement(start: nil, current: nil, diff: nil)
    
    var body: some View {

        RealityView { content, attachments in


        } update: { content, attachments in
            for model in self.models {
                
                if let entity = model.entity {

//                    let box = entity.attachment.bounds
//                    print(box.extents)
//                    

                    
                } else if let entity = attachments.entity(for: model.id) {
                    entity.components.set(InputTargetComponent())
                    
                    entity.name = model.id.debugDescription
                    entity.generateCollisionShapes(recursive: true)
                    content.add(entity)
                    entity.setPosition(SIMD3(x: 0, y: 1.5, z: -2), relativeTo: nil)
                    
//                    model.entity = entity
                    
//                    let box = entity.attachment.bounds
//                    print(box.extents)
//                    
//                    entity.addChild(model.cube)
                }
            }
        } attachments: {
            
            ForEach(self.$models) { model in
                Attachment(id: model.id) {
                    ModelView(model: model)
                }
            }
        }
        
        
    }
}
//
//#Preview(immersionStyle: .mixed) {
//    ImmersiveView(url: Bundle.main.url(forResource: "model", withExtension: "usdz")!, models: [Model(url: Bundle.main.url(forResource: "model", withExtension: "usdz")!)])
//}
