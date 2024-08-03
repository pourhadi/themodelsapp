//
//  InspectorView.swift
//  models
//
//  Created by Daniel Pourhadi on 3/7/24.
//

import SwiftUI
import RealityKit

enum AnchoredHand: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case leftHand = "Left Hand"
    case rightHand = "Right Hand"
    case none = "None"
}

struct InspectorView: View {
        
    @Binding var savedScene: SavedScene?
    
    @Binding var selectedModel: Int?
        
    @Environment(\.dismiss) var dismiss
    
    @Environment(\.modelContext) private var context
    
    var body: some View {
        HStack {
            Spacer()
            //            Spacer()
            //            Text("Selected")
            //                .font(.title)
            //                .padding()
            //            Spacer()
            
            
//            Model3D(url: model.url!) { model in
//                model
//                    .resizable()
//                    .scaledToFit()
//            } placeholder: {
//                ProgressView()
//            }
            
            if let model = self.model {
                model.inspectorModel
                    .frame(width: 400, height: 600)
                    .frame(depth: 100)
                    .padding()
            }
            /*
            Color.clear
                .frame(width: 200, height: 400)
                .overlay {
                    
                    GeometryReader3D { geometry in
                        RealityView { content in
                            
                            
                            
                        } update: { content in
                            if let existing = content.entities.first, existing.name == "\(model.id)" {
                                return
                            }
                            
                            content.entities.first?.removeFromParent()

                            let model = models[selectedModel ?? 0]
                            guard let entity = model.entity else { return }
                           
                            let dupe = entity.clone(recursive: true)
                            dupe.name = "\(model.id)"
                            
                            content.add(dupe)
                            
                            let targetSize = content.convert(geometry.frame(in: .global), from: .global, to: .scene).transformed(by: Transform(scale: SIMD3(repeating: 0.9)).matrix)
                            let currentSize = dupe.visualBounds(relativeTo: nil)
                            
                            print("target", targetSize.extents)
                            print("current", currentSize.extents)
                            
                            
                            var scale: Float = 1.0
                            
                            if currentSize.extents.y > currentSize.extents.x {
                                scale = targetSize.extents.y / currentSize.extents.y
                            } else {
                                scale = targetSize.extents.x / currentSize.extents.x
                            }
                            
                            dupe.transform.scale *= scale
//                            dupe.setScale(SIMD3(repeating: scale), relativeTo: nil)
//                            dupe.setPosition(.zero, relativeTo: nil)
                            print("position ---")
                            let framePos = targetSize.center
                            print("frame", framePos)
                            let modelPos = dupe.position(relativeTo: nil)
                            print("model", modelPos)
                            print("-----")
                            
                            let newSize = dupe.visualBounds(relativeTo: nil)
                            print("newSize", newSize.extents)
                            
                            let t = content.convert(geometry.transform(in: .global)!, from: .global, to: .scene)
//                            dupe.setTransformMatrix(t.matrix, relativeTo: nil)
//                            dupe.transform.translation = [0, -(newSize.extents.y), 0]
                            
                            dupe.setPosition([-((targetSize.extents.x - newSize.extents.x) / 2), -targetSize.extents.y / 2, 0.0], relativeTo: nil)
                            
                            let animation =  OrbitAnimation(name: "orbit",
                                                            duration: 12,
                                                            axis: SIMD3<Float>(x: 0.0, y: 1.0, z: 0),
                                                            spinClockwise: false,
                                                            orientToPath: true,
                                                            bindTarget: .transform, isAdditive: true)
                            
                            if let resource = try? AnimationResource.generate(with: animation.repeatingForever()) {
//                                dupe.playAnimation(resource)
                            }
                        }
                    }
                    
                }
            
                .padding()
             */
             Spacer()
            
            VStack {
                if hasAnimations {
                    HStack {
                        Spacer()
                        Text("Animations")
                            .font(.title2)
                            .padding()
                        
                        Button(action: {
                            if let selected = selectedModel, let model = savedScene?.models[selected].model {
                                model.playing.toggle()
                            }
                        }, label: {
                            if let model = self.model {
                                if model.playing {
                                    Image(systemName: "pause.fill")
                                        .padding(.horizontal)
                                } else {
                                    Image(systemName: "play.fill")
                                        .padding(.horizontal)
                                }
                            }
                        })
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                }
                //            Spacer()
                //            Divider()
                
                VStack {
                    Text("Attach to")
                        .font(.title2)
                    if let model = self.model {
                        @Bindable var model = model
                        Picker(selection: $model.anchoredTo) {
                            ForEach(AnchoredHand.allCases) { handCase in
                                Text(handCase.rawValue)
                                    .id(handCase)
                                    .tag(handCase)
                            }
                        } label: {
                            Text("Attach to")
                                .font(.title)
                        }.pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
                
                //            Spacer()
                
                Button {
                    if let selected = selectedModel, let model = savedScene?.models[selected].model {
                        let newModel = ModelData(url: model.url)
                        newModel.transform = model.transform
                        newModel.adjustedTransform = model.adjustedTransform
                        
                        if let saved = savedScene?.addModel(newModel) {
                            context.insert(saved)
                        }
                    }
                    
                } label: {
                    Text("Clone")
                        .font(.title)
                        .padding()
                    
                        .containerRelativeFrame(.horizontal)
                }
                .padding()
                
                
                Button {
                    if let selected = selectedModel, let savedModel = savedScene?.models[selected], let model = savedModel.model {
                        selectedModel = nil

                        model.entity?.removeFromParent()
                        model.container.removeFromParent()
                        
                        savedScene?.models.removeAll(where: { $0.id == savedModel.id })

                        context.delete(savedModel)
                    }
                    
                } label: {
                    Text("Remove from Scene")
                        .font(.title)
                        .padding()
                    
                        .containerRelativeFrame(.horizontal)
                }
                .padding()
                
//                Button {
//                    model.selected = false
//                    selectedModel = nil
//                    
//                } label: {
//                    Label("Done", systemImage: "xmark")
//                }
//                .padding()
                //            .glassBackgroundEffect()
                //            Button {
                //                selectedModel = nil
                //            } label: {
                //                Text("Done")
                //                    .font(.title)
                //                    .containerRelativeFrame(.horizontal)
                //                    .frame(height: 100)
                //            }
                //            Spacer()
            }
//            .glassBackgroundEffect()
            
            //        .overlay(alignment: .topLeading) {
            //            Button(action: {}, label: {
            //                Image(systemName: "xmark")
            //                    .padding()
            //            })
            //            .buttonBorderShape(.circle)
            //        }
            .frame(width: 400)
            .padding()
            .glassBackgroundEffect()
            
            Spacer()
            
        }
        
    }
    
    var model: ModelData? {
        if let selected = selectedModel, (savedScene?.models.count ?? 0) > selected, let model = savedScene?.models[selected].model {
            return model
        }
        
        return nil
    }
    
    
    var hasAnimations: Bool {
        guard let model = self.model else { return false }
        
        return model.animationControllers.count > 0
    }
    
    var isPlayingAnimations: Bool {
        guard let model = self.model else { return false }
        guard model.animationControllers.count > 0 else { return false }
        return model.animationControllers[0].isPlaying
    }
}

//#Preview(windowStyle:.plain) {
//    
//    struct Preview: View {
//        let mainWindowSize: CGSize = .init(width: 1000, height: 800)
//        @State var models = [ModelData(url: Bundle.main.url(forResource: "model", withExtension: "usdz")!)]
//        @State var model: Int? = 0
//        @State var background: URL? = nil
//        @State var immersion: any ImmersionStyle = MixedImmersionStyle()
//        var body: some View {
//            InspectorView(model: models[0], selectedModel: $model, models: $models)
//                .frame(width: mainWindowSize.width, height: mainWindowSize.height)
//                .glassBackgroundEffect()
//        }
//    }
//    return Preview()
//}
