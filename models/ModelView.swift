//
//  ModelView.swift
//  models
//
//  Created by Daniel Pourhadi on 2/28/24.
//

import SwiftUI
import RealityKit

struct ModelView: View {
    
    @Binding var model: ModelData
    
    @State var adjustedTransform:TransformMovement? = nil
    @State var transform: TransformMovement = TransformMovement(start: nil, current: nil, diff: nil)
    
    @State var rotating = false
    
    @State var translationStart: Vector3D? = nil
    
//    @ObservedObject var handTracking: HandTrackingModel
    var body: some View {
        GeometryReader3D { proxy in
            Model3D(url: model.url!) { model in
                model.model?
                    .resizable()
                    .aspectRatio(contentMode: .fit)
//                    .rotation3DEffect(self.transform.rotation ?? Rotation3D(), anchor: .center)

            }
            

            
            .coordinateSpace(name: model.id)
            
            .gesture(DragGesture()
                .handActivationBehavior(.pinch)
                .onChanged({ value in

                    
                    if !model.interacting {
                        model.interacting = true
                        withAnimation(.bouncy) {
                            self.transform.scale += self.transform.scale * 0.2
                        }
                    }
                    if let start = translationStart {
                        self.transform.translation = start + value.translation3D
                    } else {
                        if let translation = self.transform.translation {
                            self.translationStart = translation
                        } else {
                            self.transform.translation = .zero
                        }
//                        translationStart = self.transform.translation
                    }
                    
                }).onEnded({ value in
                    
                    model.interacting = false
                    withAnimation(.bouncy) {
                        self.transform.scale -= self.transform.scale * 0.2
                    }
                    
                    self.adjustedTransform = self.transform
                    self.transform.start = nil
                    self.transform.startT = nil
                    self.translationStart = nil
                })
                    .simultaneously(with: RotateGesture3D().onChanged({ value in
                        
                        //                    var rot = value.convert(value.rotation, from: .local, to: value.entity)
                        
                        
                        var rot = value.rotation
                        if let adj = self.adjustedTransform, let adjRotation = adj.rotation {
                            rot = rot.rotated(by: adjRotation)
                        }
                        self.transform.rotation = rot
                        
                    }).onEnded({ value in
                        
                        self.adjustedTransform = self.transform
                    }))
                        .simultaneously(with: MagnifyGesture().onChanged({ value in
                            
                            if let startScale = self.transform.startScale {
                                self.transform.scale = max(0.1, min(3, value.magnification * startScale))
                                
                                if let adj = self.adjustedTransform {
                                    self.transform.scale *= adj.scale
                                }
                                
                            } else {
                                self.transform.startScale = self.transform.scale
                            }
                            //
                            
                            //                            self.transform.scale = max(0.1, min(3, value.magnification * self.transform.scale))
                            //                            if let adj = model.adjustedTransform {
                            //                                self.transform.scale *= adj.scale
                            //                            }
                            //
                            print("setting scale \(self.transform.scale)")
                            
                            
                        }).onEnded({ value in
                            
                            self.adjustedTransform = self.transform
                            self.transform.startT = nil
                            //                            self.transform.startScale = nil
                        }).simultaneously(with: SpatialTapGesture().onEnded({ value in
                            
                            print("tapped \(model.url)")
                            model.selected.toggle()
                            
                            //                        selectedModel = selectedModel == model ? nil : model
                        })))
            )
        
            
            }
        .offset(x: self.transform.translation?.x ?? 0,
                y: self.transform.translation?.y ?? 0)
        .offset(z: self.transform.translation?.z ?? 0)
        .scaleEffect(self.transform.scale)

    }
}

//#Preview {
//    ModelView()
//}
