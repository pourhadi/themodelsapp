//
//  FullViewSpace.swift
//  models
//
//  Created by Daniel Pourhadi on 3/6/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct FullViewSpace: View {
    @Binding var models: [ModelData]
    
    @Binding var backgroundUrl: URL?
    
    @State var selectedModel: ModelData?
    
    
    var body: some View {
        RealityView { content, attachments in
            if let scene = try? await Entity.init(named: "Scene", in: realityKitContentBundle) {
                
                content.add(scene)
                            
            }
        } update: { content, attachments in
            guard let scene = content.entities.first else { return }
            
            for model in self.models {
                if let entity = attachments.entity(for: model.id), entity.scene == nil {
                    scene.addChild(entity)
                    
                    entity.setPosition(SIMD3(x: 0, y: 1.5, z: -2), relativeTo: nil)

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

//#Preview {
//    FullViewSpace()
//}
