//
//  modelsApp.swift
//  models
//
//  Created by Daniel Pourhadi on 2/28/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import SwiftData

@main
struct modelsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State var models = [ModelData]()
    
    @State private var currentStyle: ImmersionStyle = MixedImmersionStyle()
    
    @State var selectedModel: Int? = nil
    
    @State var showingMainWindow = true
    
    @State var showImmersiveSpace = false
    
    @State var savedScene: SavedScene?
    
    @State var hasUnsavedChanges = false
    
    @State var immersiveShown = false
    
    let mainWindowSize: CGSize = .init(width: 1016, height: 775)

    let modelContainer: ModelContainer
    
    @AppStorage("currentSceneId") var currentScene: PersistentIdentifier?
    
    @Environment(\.scenePhase) var scenePhase
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    init() {
        GestureComponent.registerComponent()

        self.modelContainer = try! ModelContainer(for: SavedScene.self, SavedModel.self, configurations: .init(cloudKitDatabase: .none))
    }
    
    var body: some SwiftUI.Scene {
        WindowGroup(id: "main") {
            ContentView(savedScene: $savedScene, hasUnsavedChanges: $hasUnsavedChanges, models: $models, selectedModel: $selectedModel, immersionStyle: $currentStyle, showImmersiveSpace: $showImmersiveSpace)
                .windowSize(mainWindowSize)
                .modelContainer(modelContainer)
                .onDisappear(perform: {
                    self.showingMainWindow = false
                })
                .onAppear(perform: {
                    self.showingMainWindow = true
                })
                
        }
        .defaultSize(mainWindowSize)
        .windowResizability(.contentMinSize)
        .onChange(of: scenePhase) { oldValue, newValue in
            print(newValue)
            if newValue == ScenePhase.background {
                Task {
                    await dismissImmersiveSpace()
                    savedScene = nil
                    showImmersiveSpace = false
                }
            }
        }
        

        ImmersiveSpace(id: "Space") {
            FullSpace(savedScene: $savedScene, hasUnsavedChanges: $hasUnsavedChanges, selectedModel: $selectedModel, showingMainWindow: $showingMainWindow)
//                .upperLimbVisibility(.hidden)
                .modelContainer(modelContainer)
                .onAppear {
                   immersiveShown = true
                    print("immersive shown")
                }
                .onDisappear {
                    print("immersive disappeared")
                }

        }.immersionStyle(selection: $currentStyle, in: MixedImmersionStyle(), ProgressiveImmersionStyle())
        
//        WindowGroup(id: "inspector") {
//            if let model = selectedModel {
//                InspectorView(model: model)
//                    .windowSize(.init(width: 400, height: 800))
//            } else {
//                EmptyView()
//            }
//        }
//        .defaultSize(.init(width: 400, height: 800))
    }
}



//@MainActor
//enum HandTrackingModelContainer {
//    private(set) static var handTrackingModel = HandTrackingModel()
//}
