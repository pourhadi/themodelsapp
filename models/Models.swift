//
//  Models.swift
//  models
//
//  Created by Daniel Pourhadi on 3/19/24.
//

import Foundation
import SwiftData
import RealityKit
import SwiftUI

let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.pourhadi.models")

@Model
class SavedScene {
    
    var id: UUID! = UUID()
    var name: String?
    @Relationship var models: [SavedModel] = []
    
    var backgroundUrl: URL? {
        didSet {
            if backgroundUrl != nil {
                customModelBackgroundUrl = nil
            }
        }
    }

    var customModelBackgroundUrl: URL? {
        didSet {
            if customModelBackgroundUrl != nil {
                backgroundUrl = nil
            }
        }
    }
    
    var createdAt: Date = Date()
    var lastUpdated: Date = Date()
    
    init(id: UUID = UUID(), name: String? = "Scene", backgroundUrl: URL? = nil, customModelBackgroundUrl: URL? = nil, createdAt: Date = Date(), lastUpdated: Date = Date()) {
        self.name = name
        self.backgroundUrl = backgroundUrl
        self.customModelBackgroundUrl = nil
        self.id = id
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
    }
    
    func addModel(_ model: ModelData) -> SavedModel {
        let savedModel = SavedModel(model: model)
        
//        let destUrl = sceneUrl.appending(path: savedModel.id.uuidString).appendingPathExtension("usdz")
        
//        print("adding model")
//        print("scene", id)
//        print("model", savedModel.id)
//        print("source url", model.url!)
//        print("dest url", destUrl)
//        do {
//            try FileManager.default.copyItem(at: model.url!, to: destUrl)
//        } catch {
//            print(error)
//        }
//        
        savedModel.url = model.url
        models.append(savedModel)
        savedModel.savedScene = self
        
        lastUpdated = Date()
        return savedModel
    }
    
    var sceneUrl: URL {
        return containerUrl!.appending(path: id.uuidString)
    }
    
    func save() {
        lastUpdated = Date()
        for savedModel in models {
            if let modelData = savedModel.model {
                savedModel.transform = Transform(matrix: modelData.container.transformMatrix(relativeTo: nil))
            } else {
                print("saved model doesn't have model data when trying to save")
            }
        }
    }

}

@Model
class SavedModel {
    var id: UUID! = UUID()
    var url: URL?
    var name: String?
    var position: [Float] = [0,0,0]
    var scale: [Float] = [0,0,0]
    var rotation: [Float] = [0,0,0,0]
    
    @Relationship(inverse: \SavedScene.models) var savedScene: SavedScene? = nil
    
    init(id: UUID? = UUID(), url: URL? = nil, name: String? = nil, position: [Float] = [0,0,0], scale: [Float] = [0,0,0], rotation: [Float] = [0,0,0,0]) {
        self.id = id
        self.url = url
        self.name = name
        self.position = position
        self.scale = scale
        self.rotation = rotation
    }
    
    @Transient var transform: Transform {
        get {
            return Transform(
                scale: [scale[0], scale[1], scale[2]],
                rotation: simd_quatf(vector: .init(x: rotation[0], y: rotation[1], z: rotation[2], w: rotation[3])),
                translation: [position[0], position[1], position[2]]
            )
        }
        set {
            self.position = [newValue.translation.x, newValue.translation.y, newValue.translation.z]
            self.scale = [newValue.scale.x, newValue.scale.y, newValue.scale.z]
            self.rotation = [newValue.rotation.vector.x, newValue.rotation.vector.y, newValue.rotation.vector.z, newValue.rotation.vector.w]
        }
    }
    
    @MainActor func restoreEntity() async throws -> ModelData {
        guard let url = url, let entity = try? await Entity(contentsOf: url) else {
            throw "can't load entity"
        }
        
        let modelData = ModelData(url: url, entity: entity)
        modelData.name = name
        entity.name = name ?? "no name"
        self.model = modelData
        modelData.savedModel = self
        return modelData
    }
    
    init(model: ModelData) {
        self.id = UUID()
        self.url = model.url
        self.transform = model.container.transform
        self.name = model.name
        self.model = model
        model.savedModel = self
    }
    
    @Transient var model: ModelData? = nil
    
}

@Observable
class ModelData: Identifiable, Equatable {
    
    var savedModel: SavedModel? = nil
    
    var name: String? = nil
    
    static func == (lhs: ModelData, rhs: ModelData) -> Bool {
        lhs.id == rhs.id
    }
    
    var url: URL?
    
    var savedScene: SavedScene?
    
    init(url: URL? = nil, entity: Entity? = nil, containerTransform: Transform? = nil, entityTransform: Transform? = nil, boxTransform: Transform? = nil) {
        self.url = url
        
        self.containerTransform = containerTransform
        self.entityTransform = entityTransform
        self.boxTransform = boxTransform
        
        self.entity = entity
        Task {
            guard let url = url, self.entity == nil else { return }
            do {
                self.entity = try await Entity(contentsOf: url)
            } catch {
                print(error)
            }
        }
    }
    
    var adjustedTransform: TransformMovement? = nil
    var transform: TransformMovement = TransformMovement(start: nil, current: nil, diff: nil)
    
    var entity: Entity? = nil
    
    var cube: ModelEntity = ModelEntity(mesh: .generateBox(size: 1), materials: [UnlitMaterial(color: .white.withAlphaComponent(0.5))])
    
    var selected = false
    
    var container = Entity()
    
    var box: Entity?
    
    var interacting = false
    
    var originalTransform = Transform.identity
    
    var containerTransform: Transform?
    
    var entityTransform: Transform?
    
    var boxTransform: Transform?
    
    var animationControllers: [AnimationPlaybackController] = []
    
    var playing = false {
        didSet {
            if playing {
                animationControllers.forEach { $0.resume() }
            } else {
                animationControllers.forEach { $0.pause() }
            }
        }
    }
    
    var addedToScene = false
    
    var anchoredTo: AnchoredHand = AnchoredHand.none {
        didSet {
            if anchoredTo != oldValue {
                switch anchoredTo {
                case .leftHand:
                    leftHand?.addChild(container)
                    let rotation = Rotation3D.init(angle: .init(degrees: 180), axis: .x)
                    let originalRotation = Rotation3D(container.transform.rotation)
                    container.setPosition([0.0, 0.1, 0.0], relativeTo: rightHand)
                    
                    container.gestureComponent?.anchoredToHand = true
                case .rightHand:
                    rightHand?.addChild(container)
                    let rotation = Rotation3D.init(angle: .init(degrees: 180), axis: .x)
                    let originalRotation = Rotation3D(container.transform.rotation)
                    container.setPosition([0.0, 0.1, 0.0], relativeTo: rightHand)
                    container.gestureComponent?.anchoredToHand = true

                case .none:
                    scene?.addChild(container)
                    
                    container.gestureComponent?.anchoredToHand = false

                }
            }
        }
    }
    
    var scene: Entity?
    var leftHand: AnchorEntity?
    var rightHand: AnchorEntity?
    
    var resolvedModel: (any View)?
    var __inspectorModel: (any View)?
    var inspectorModel: some View {
        if let view = resolvedModel {
            return AnyView(view).tag(id).id(id)
        }
        
        let mv = Model3D(url: self.url!) { model in
            
            model
                .resizable()
                .scaledToFit()
                .task {
                    self.resolvedModel = model.resizable().scaledToFit()
                }
        } placeholder: {
            ProgressView()
        }
        
        return AnyView(mv).tag(id).id(id)
    }
}


extension String: Error {}
