//
//  FullSpace.swift
//  models
//
//  Created by Daniel Pourhadi on 3/1/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import AVKit
import SwiftData


protocol ModelPresentable: Identifiable {
    var title: String { get }
    var thumbnailUrl: URL? { get }
    var url: URL? { get }
}




extension Transform : Codable {
    
    public func encode(to encoder: any Encoder) throws {
        let columns = matrix.columns
        var container = encoder.singleValueContainer()
        try? container.encode([[columns.0.x, columns.0.y, columns.0.z, columns.0.w],
                               [columns.1.x, columns.1.y, columns.1.z, columns.1.w],
                               [columns.2.x, columns.2.y, columns.2.z, columns.2.w],
                               [columns.3.x, columns.3.y, columns.3.z, columns.3.w]])
    }
    
    public init(from decoder: any Decoder) throws {
        if let columns = try? decoder.singleValueContainer().decode(Array<Array<Float>>.self) {
            let matrix = float4x4.init(SIMD4(columns[0]), SIMD4(columns[1]), SIMD4(columns[2]), SIMD4(columns[3]))
            
            self.init(matrix: matrix)
        } else {
            print("error decoding")
            self.init()
        }
    }
    
    
}


extension Sequence where Element == ModelData {
    func model(for entity: Entity) -> ModelData? {
        return self.first { model in
            model.container == entity || model.entity == entity
        }
    }
}

struct FullSpace: View {
    
    var models: [ModelData] {
        savedScene?.models.compactMap { $0.model } ?? []
    }
    
    @Binding var savedScene: SavedScene?
    
    @Binding var hasUnsavedChanges: Bool
    
    //    @Binding var models: [ModelData]
    
    @State var backgroundUrl: URL? = nil
    
    @Binding var selectedModel: Int?
    
    @Binding var showingMainWindow: Bool
    
    @State var showRemoveConfirmation = false
    
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    @State var showInspector = false
    
    @State var selectionHandled = false
    
    let leftHand = AnchorEntity(.hand(.left, location: .palm))
    let rightHand = AnchorEntity(.hand(.right, location: .palm))
    
    let headAnchor = AnchorEntity(.head)
    
    @State var cancellable: Any?
    @State var cancellable2: Any?
    
    @State var interacting = false
    
    @Environment(\.modelContext) private var context
    
    @State var lastUpdatedSceneId: PersistentIdentifier? = nil
    var body: some View {
        ZStack {
            RealityView { content, attachments in
                if let scene = try? await Entity.init(named: "Immersive", in: realityKitContentBundle) {
                    scene.name = "scene"
                    content.add(scene)
                    
                    scene.addChild(headAnchor)
                    
                    scene.addChild(leftHand)
                    scene.addChild(rightHand)
                    
                    if let savedScene = self.savedScene {
                        
                        if let bgUrl = savedScene.backgroundUrl, bgUrl != backgroundUrl {
                            
                            if let bg = scene.findEntity(named: "background") {
                                bg.removeFromParent()
                            }
                            
                            addBackground(url: bgUrl, entity: scene)
                        } else if let modelBgUrl = savedScene.customModelBackgroundUrl, modelBgUrl != backgroundUrl {
                            if let bg = scene.findEntity(named: "background") {
                                bg.removeFromParent()
                            }
                            addModelBackground(url: modelBgUrl, entity: scene)

                        } else if savedScene.backgroundUrl == nil && savedScene.customModelBackgroundUrl == nil {
                            if let bg = scene.findEntity(named: "background") {
                                bg.removeFromParent()
                            }
                        }
                        
                        for savedModel in savedScene.models {
                            if let model = savedModel.model {
                                add(model: model, to: scene)
                            } else {
                                if let model = try? await savedModel.restoreEntity() {
                                    savedModel.model = model
                                    add(model: model, to: scene, restoring: savedModel.transform)
                                }
                                
                            }
                        }
                        lastUpdatedSceneId = savedScene.persistentModelID
                    }
                    
                }
            } update: { content, attachments in
                print("update called")
                guard let scene = content.entities.first,
                      let remove = attachments.entity(for: "remove") else { return }
                
                if lastUpdatedSceneId != savedScene?.persistentModelID {
                    if let savedScene = self.savedScene {
                        
                        scene.removeFromParent()
                        if let scene = try? Entity.load(named: "Immersive", in: realityKitContentBundle) {
                            scene.name = "scene"
                            content.add(scene)
                            
                            if let bgUrl = savedScene.backgroundUrl, bgUrl != backgroundUrl {
                                
                                if let bg = scene.findEntity(named: "background") {
                                    bg.removeFromParent()
                                }
                                
                                addBackground(url: bgUrl, entity: scene)
                            } else if let modelBgUrl = savedScene.customModelBackgroundUrl, modelBgUrl != backgroundUrl {
                                if let bg = scene.findEntity(named: "background") {
                                    bg.removeFromParent()

                                }
                                addModelBackground(url: modelBgUrl, entity: scene)

                            } else if savedScene.backgroundUrl == nil && savedScene.customModelBackgroundUrl == nil {
                                if let bg = scene.findEntity(named: "background") {
                                    bg.removeFromParent()
                                }
                            }
                            
                            Task {
                                lastUpdatedSceneId = savedScene.persistentModelID
                                
                                
                                scene.addChild(headAnchor)
                                
                                scene.addChild(leftHand)
                                scene.addChild(rightHand)
                                
                                for savedModel in savedScene.models {
                                    if let model = savedModel.model {
                                        add(model: model, to: scene)
                                    } else {
                                        if let model = try? await savedModel.restoreEntity() {
                                            savedModel.model = model
                                            add(model: model, to: scene, restoring: savedModel.transform)
                                        }
                                        
                                    }
                                }
                            }
                        }
                    }
                } else {
                    
                    if let bgUrl = self.savedScene?.backgroundUrl, bgUrl != backgroundUrl {
                        
                        if let bg = scene.findEntity(named: "background") {
                            bg.removeFromParent()
                        }
                        
                        addBackground(url: bgUrl, entity: scene)
                    } else if let modelBgUrl = self.savedScene?.customModelBackgroundUrl, modelBgUrl != backgroundUrl {
                        if let bg = scene.findEntity(named: "background") {
                            bg.removeFromParent()

                        }
                        addModelBackground(url: modelBgUrl, entity: scene)

                    } else if self.savedScene?.backgroundUrl == nil && self.savedScene?.customModelBackgroundUrl == nil {
                        if let bg = scene.findEntity(named: "background") {
                            bg.removeFromParent()
                        }
                    }
                    
                    for (idx, savedModel) in self.savedScene!.models.enumerated() {
                        if let model = savedModel.model {
                            if idx != selectedModel {
                                model.box?.removeFromParent()
                            }
                            if let _ = model.entity,
                               let scene = content.entities.first {
                                
                                if model.container.scene == nil {
                                    add(model: model, to: scene)
                                }
                            }
                        } else {
                            Task {
                                if let model = try? await savedModel.restoreEntity() {
                                    savedModel.model = model
                                    add(model: model, to: scene)
                                }
                            }
                        }
                    }
                }
                
                
                //                if let selectedModel = selectedModel,
                //                    let attachment = attachments.entity(for: "inspector"),
                //                   attachment.parent == nil {
                //                    content.entities.first?.addChild(attachment)
                //                    attachment.name = "inspector"
                //                    let model = models[selectedModel]
                //                    let size = model.container.visualBounds(relativeTo: nil).extents
                //                    let pos = model.container.position(relativeTo: nil)
                //                    let x = min(-0.1, max(0.1, pos.x + size.x))
                //                    let y = min(-0.1, max(0.1, pos.y + size.y))
                //
                //                    attachment.setPosition([x, y, -0.5], relativeTo: nil)
                //
                ////                    attachment.setScale(.one, relativeTo: nil)
                ////                    attachment.setPosition([0.05, 0.0, -0.5], relativeTo: nil)
                //                } else if selectedModel == nil, let attachment = attachments.entity(for: "inspector") {
                //                    attachment.removeFromParent()
                //                }
                
                
            } attachments: {
                
                Attachment(id: "inspector") {
                    EmptyView()
                }
                
                Attachment(id: "remove") {
                    
                    EmptyView()
                }
            }
            .installGestures(SpatialTapGesture().targetedToAnyEntity().handActivationBehavior(.pinch).onEnded({ value in
                guard let model = models.model(for: value.entity) else {
                    if !showingMainWindow {
                        showingMainWindow = true
                        openWindow(id: "main")
                    } else {
                        showingMainWindow = false
                        dismissWindow(id: "main")
                    }
                    return
                }
                
                
                if (!showingMainWindow) {
                    showingMainWindow = true
                    openWindow(id: "main")
                }
                
                print("Tap")
                
                if let index = models.firstIndex(of: model) {
                    
                    selectedModel = selectedModel == index ? nil : index
                    
                }
                
                hasUnsavedChanges = true
            })
                .simultaneously(with: SpatialEventGesture().targetedToAnyEntity().handActivationBehavior(.pinch).onChanged({ value in
                guard let model = models.model(for: value.entity) else { return }
                
                if !model.interacting {
                    
                    hasUnsavedChanges = true
                    model.interacting = true
                    self.interacting = true
                    if let entity = model.entity {
                        model.originalTransform = Transform(matrix: entity.transformMatrix(relativeTo: model.container))
                        
                        var transform = Transform(matrix: entity.transformMatrix(relativeTo: entity))
                        transform.scale = .init(repeating: 1.05)
                        model.container.components.set(HoverEffectComponent())
                        
                        entity.move(to: transform, relativeTo: entity, duration: 0.1, timingFunction: .easeOut)
                        
                        //                        entity.setScale(.init(repeating: 1.05), relativeTo: entity)
                    }
                }
            }).onEnded({ value in
                guard let model = models.model(for: value.entity) else { return }
                
                if model.interacting {
                    //                    model.entity?.transform.scale = model.originalScale
                    model.interacting = false
                    self.interacting = false
                    model.entity?.move(to: model.originalTransform, relativeTo: model.container, duration: 0.1, timingFunction: .easeOut)
                    model.container.components.remove(HoverEffectComponent.self)
                }
                hasUnsavedChanges = true
            })))
            .onChange(of: selectedModel) { oldValue, newValue in
                showInspector = newValue != nil
                
                selectionHandled = false
                handleSelection()
                if (!showingMainWindow) {
                    showingMainWindow = true
                    openWindow(id: "main")
                }
            }
            .onChange(of: hasUnsavedChanges) { oldValue, newValue in
                guard newValue else { return }
                self.savedScene?.save()
                
                try? context.save()
                
                hasUnsavedChanges = false
            }
//            .onChange(of: savedScene?.backgroundUrl, { oldValue, newValue in
//                self.backgroundUrl = newValue
//            })
            .id(savedScene?.id ?? UUID())
            
        }
    }
    
    func handleSelection() {
        if let selectedIndex = selectedModel,
            let entity = models[selectedIndex].entity,
           models[selectedIndex].box == nil,
           !selectionHandled {
            selectionHandled = true
            let selected = models[selectedIndex]
            let extents = entity.visualBounds(recursive: true, relativeTo: selected.container)
            print(extents)
            var mat = PhysicallyBasedMaterial()
            mat.blending = .transparent(opacity: 0.4)
            mat.clearcoat = .init(floatLiteral: 1)
            mat.clearcoatRoughness = .init(floatLiteral: 0.5)
            mat.roughness = 0.0
            
            let largest = max(max(extents.extents.x, extents.extents.z), extents.extents.y)
            
            
            let box = ModelEntity(mesh: .generateBox(size: extents.extents), materials: [mat])
            selected.box = box
            
            
            if let s = try? Entity.load(named: "selection", in: realityKitContentBundle) {
                selected.box = s
                selected.container.addChild(s)
                
                let selectionBounds = s.visualBounds(relativeTo: selected.container)
                
                s.setScale(extents.extents / selectionBounds.extents, relativeTo: selected.container)
            }
            
            var particles = ParticleEmitterComponent.Presets.magic
            particles.timing = .repeating(warmUp: 0, emit: .init(duration: 1), idle: .none)
            particles.emitterShape = .box
            particles.isEmitting = true
            //            box.components.set(particles)
            
            let animation =  OrbitAnimation(name: "orbit",
                                            duration: 12,
                                            axis: SIMD3<Float>(x: 0.0, y: 1.0, z: 0),
                                            spinClockwise: false,
                                            orientToPath: true,
                                            bindTarget: .transform)
            
            if let resource = try? AnimationResource.generate(with: animation.repeatingForever()) {
                //                box.playAnimation(resource)
            }
            
            
            
        } else if let selectedIndex = selectedModel,
                  let entity = models[selectedIndex].entity,
                  let box = models[selectedIndex].box,
                  !selectionHandled {
            selectionHandled = true
            
            let model = models[selectedIndex]
            model.container.addChild(box)
        }
    }
    
    func add(model: ModelData, to scene: Entity, restoring transform: Transform? = nil) {
        guard let entity = model.entity, !model.addedToScene else { return }
        
        let extents = entity.visualBounds(relativeTo: scene)
        
        model.addedToScene = true
        scene.addChild(model.container)
        model.container.addChild(entity)
        model.container.name = "container_\(model.name ?? model.url?.lastPathComponent ?? UUID().uuidString)"
        let container = model.container
        entity.transform.translation -= entity.visualBounds(relativeTo: container).center
        print("drawing model")
        model.container.components.set(InputTargetComponent())
        entity.name = model.name ?? model.url?.lastPathComponent ?? UUID().uuidString
        
        entity.components.set(GroundingShadowComponent(castsShadow: true))
        
        let size = extents.extents
        
        
        
        let largest = max(extents.extents.x, extents.extents.y, extents.extents.z)
        
        let col = CollisionComponent(shapes: [.generateBox(size: extents.extents)])
        model.container.components.set(col)   //
        
        let scale = 0.3 / largest
        print("start scale \(scale)")
        model.container.setPosition(SIMD3(x: 0, y: 1, z: -1.5), relativeTo: nil)
        
        model.container.transform.scale = SIMD3(repeating: scale)
        
        model.transform.scale = CGFloat(scale)
        
        if let transform = transform {
            model.container.setTransformMatrix(transform.matrix, relativeTo: nil)
            model.transform.scale = CGFloat(transform.scale.x)
        }
        
        model.animationControllers = entity.availableAnimations.map { animation in
            return entity.playAnimation(animation.repeat())
        }
        model.playing = true
        
        model.scene = scene
        model.leftHand = leftHand
        model.rightHand = rightHand
        
        DispatchQueue.main.async {
            var particles = ParticleEmitterComponent.Presets.impact
            particles.emitterShape = .sphere
            particles.emitterShapeSize = .one // * 3
            //            particles.particlesInheritTransform = true
            particles.timing = .once(warmUp: nil, emit: .init(duration: 0.025))
            particles.isEmitting = true
            
            model.entity?.components.set(particles)
        }
        
        
        
        var component = GestureComponent.init()
        component.canDrag = true
        component.canScale = true
        component.canRotate = true
        
        model.container.components.set(component)
        
        hasUnsavedChanges = true
        
        //        model.container.components.set(HoverEffectComponent())
    }
    
    //    func remove(model: ModelData) {
    //        models.removeAll(where: { $0.id == model.id })
    //
    //        model.entity?.removeFromParent()
    //        model.container.removeFromParent()
    //        model.container.isEnabled = false
    //
    //        hasUnsavedChanges = true
    //    }
    //
    
    func addModelBackground(url: URL, entity: Entity) {
        
        hasUnsavedChanges = true
        
        Task {
            backgroundUrl = url
        }
        
        if let model = try? Entity.loadModel(contentsOf: url) {
            
            entity.addChild(model)
            
            let bounds = model.visualBounds(relativeTo: nil)
            
//            let scale = 1E3 / bounds.boundingRadius
            
            //                model.transform.scale *= SIMD3(repeating: scale)
//            model.scale *= .init(x: -1, y: 1, z: 1)
            
//            model.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
            model.name = "background"
            
        }
    }
    
    func addBackground(url: URL, entity: Entity) {
        
        hasUnsavedChanges = true
        
        Task {
            backgroundUrl = url
        }
        
        if url.pathExtension == "usdz" {
            
            if let model = try? ModelEntity.loadModel(contentsOf: url) {
                
                entity.addChild(model)
                
                let bounds = model.visualBounds(relativeTo: nil)
                
                let scale = 1E3 / bounds.boundingRadius
                
                //                model.transform.scale *= SIMD3(repeating: scale)
                model.scale *= .init(x: -1, y: 1, z: 1)
                
                model.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
                model.name = "background"
                
            }
            
            
        } else {
            
            do {
                let texture = try TextureResource.load(contentsOf: url)
                var material = SimpleMaterial()
                
                material.color = SimpleMaterial.BaseColor(texture: MaterialParameters.Texture(texture))
                // Instantiate and configure the video material.
                //        let material = VideoMaterial(avPlayer: player)
                
                let model = ModelEntity(
                    mesh: .generateSphere(radius: 1E3),
                    materials: [material]
                )
                
                model.scale *= .init(x: -1, y: 1, z: 1)
                model.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
                
                model.name = "background"
                
                entity.addChild(model)
                
                /*
                 Task {
                 if let resource = try? await EnvironmentResource.init(named: "clouds") {
                 print("got resource")
                 
                 let lighting = ImageBasedLightComponent(source: .single(resource))
                 
                 await model.components.set(lighting)
                 await model.components.set(ImageBasedLightReceiverComponent(imageBasedLight: model))
                 
                 await MainActor.run {
                 entity.children.forEach { e in
                 e.components.set(ImageBasedLightReceiverComponent(imageBasedLight: model))
                 }
                 }
                 
                 }
                 
                 }
                 */
            }
            catch {
                print(error)
            }
        }
        
    }
    
    func placeModelEnvironment(url: URL, entity: Entity) async {
        
    }
    
}

//#Preview {
//    FullSpace()
//}
