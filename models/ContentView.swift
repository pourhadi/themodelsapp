//
//  ContentView.swift
//  models
//
//  Created by Daniel Pourhadi on 2/28/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import SwiftData

extension Int: Identifiable {
    public var id: Int {
        self
    }
}

struct ContentView: View {

    enum Tab: Hashable {
        case models
        case environments
        case scenes
    }

    @Binding var savedScene: SavedScene?

//    @Binding var selectedSceneId: PersistentIdentifier?

    @Binding var hasUnsavedChanges: Bool

    @Binding var models: [ModelData]

    @Binding var selectedModel: Int?

    var backgroundUrl: URL? {
        savedScene?.backgroundUrl
    }

    @Binding var immersionStyle: ImmersionStyle

    @Binding var showImmersiveSpace: Bool
    @State private var immersiveSpaceIsShown = false

    @State var pickingBackground = false
    @State var showFilePicker = false

    @State var url: URL?

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    @Environment(\.openWindow) var openWindow


    @State var publicModels = [PublicModel]()
    @State var environments = [PublicEnvironment]()

    @Environment(\.modelContext) private var context

    @Query var scenes: [SavedScene]

    @State var findMoreModels = false
    @State var findMoreEnvironments = false

    @State var selectedTab = Tab.models
    
    var body: some View {

        ZStack {
//            if let selected = selectedModel {
//                InspectorView(model: models[selected], selectedModel: $selectedModel, models: $models)
//
//                    .padding()
//            } else {
//

            TabView(selection: $selectedTab) {
                modelView
                .tabItem {
                    Label("Models", systemImage: "shippingbox.fill")
                }
                .tag(Tab.models)

                environmentView
                .tabItem {
                    Label("Environments", systemImage: "globe.americas.fill")
                }
                .tag(Tab.environments)

                ScenesView(selectedScene: $savedScene)
                .tabItem {
                    Label("Scenes", systemImage: "photo.fill")
                }
                .tag(Tab.scenes)

            }

//            }


        }
//        .padding()

        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    switch await openImmersiveSpace(id: "Space") {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: pickingBackground ? [.image] : [.usdz], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let files):

                files.forEach { file in
                    // gain access to the directory
                    let gotAccess = file.startAccessingSecurityScopedResource()
                    if !gotAccess {
                        return
                    }
                    Task {

                        if pickingBackground {
                            setBackground(url: file)
                            self.immersionStyle = ProgressiveImmersionStyle()
                        } else {

                            addEntity(url: file, name: file.lastPathComponent.replacingOccurrences(of: file.pathExtension, with: ""))

                        }
                    }
                }

            default:
                return
            }
        }
        .task {
            self.publicModels = await Cloud.getPublicVideos()
            
            self.environments = await Cloud.getPublicEnvironments()
        }
        .fullScreenCover(item: $selectedModel, content: { selected in
            InspectorView(savedScene: $savedScene, selectedModel: $selectedModel)
                .padding()
        })

        .ornament(visibility: savedScene == nil && scenes.count < 1 ? .hidden : .visible, attachmentAnchor: .scene(.bottom)) {
            HStack {

                if savedScene == nil {
                    Button {
                        selectedTab = .scenes
                    } label: {
                        Text("Load a Scene")
                            .padding()
                    }

                } else {
                    VStack {
                        Text(savedScene?.name ?? "")
                            .font(.title)
                        Text("\(savedScene?.models.count ?? 0) \((savedScene?.models.count ?? 0) > 1 || (savedScene?.models.count ?? 0) == 0 ? "models" : "model")")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding()


                    Button {
                        self.savedScene = newScene()
                    } label: {
                        Text("New Scene")
                            .padding()
                    }

                }
            }
            .padding()
            .glassBackgroundEffect()

//            Toggle(isOn: $showImmersiveSpace) {
//                Text("Immersive")
//            }
//            .padding()
//            .glassBackgroundEffect()
        }
        .onChange(of: savedScene) { oldValue, newValue in
            if let oldScene = oldValue {
                oldScene.models.forEach {
                    $0.model = nil
                }
            }

            if newValue != nil {
                DispatchQueue.main.async {
                    showImmersiveSpace = true
                }
            }

//            Task {
//                if let scene = savedScene {
//                    switch await openImmersiveSpace(id: "Space", value: scene.persistentModelID) {
//                    case .opened:
//                        immersiveSpaceIsShown = true
//                    case .error, .userCancelled:
//                        fallthrough
//                    @unknown default:
//                        immersiveSpaceIsShown = false
//                        showImmersiveSpace = false
//                    }
//                } else if immersiveSpaceIsShown {
//                    await dismissImmersiveSpace()
//                    immersiveSpaceIsShown = false
//                }
//            }
        }
        .fullScreenCover(isPresented: $findMoreModels) {
            VStack(alignment: .center, spacing: 14) {
                Spacer()
                Text("The Models App can import USDZ models.").font(.largeTitle)
//                Divider()
                Spacer()
                Text("Sketchfab supports downloads in the USDZ format for most of its models,\nso probably has one of the largest selections available online.").font(.system(size: 20))
                Link("Sketchfab", destination: URL(string: "https://www.sketchfab.com")!).font(.system(size: 20))
//                Divider()
                Spacer()
                Text("You can also use apps like Blender\nto convert models of other formats into USDZ.").font(.system(size: 20))
                Link("Blender", destination: URL(string: "https://www.blender.org")!).font(.system(size: 20))
                Spacer()
                Button {
                    findMoreModels = false
                } label: {
                    Text("Done")
                        .padding()
                }
                Spacer()

            }
            .multilineTextAlignment(.center)
            .padding(20)
        }
        .fullScreenCover(isPresented: $findMoreEnvironments) {
            VStack(alignment: .center, spacing: 14) {
                Spacer()
                Image(systemName: "info.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                Spacer()
                Text("An Environment is an image or video projected on\nthe inside of a sphere that surrounds you\n(often referred to as a \"skybox\").").font(.system(size: 20))
                Spacer()
                Text("Panoramas, equirectangular images,\nor 360° videos tend to work best\n(the higher the resolution the better).").font(.system(size: 20))
                Spacer()
                Button {
                    findMoreEnvironments = false
                } label: {
                    Text("Done")
                        .padding()
                }
                Spacer()

            }
            .multilineTextAlignment(.center)
            .padding(20)
        }
        .onChange(of: backgroundUrl) { oldValue, newValue in
            if newValue == nil {
                self.immersionStyle = MixedImmersionStyle()
            }
        }

    }

    func setBackground(url: URL, customModel: Bool = false) {
        let scene = savedScene ?? newScene()

        try? FileManager.default.createDirectory(at: scene.sceneUrl, withIntermediateDirectories: true)

        let destUrl = scene.sceneUrl.appending(path: "\(UUID().uuidString)_background").appendingPathExtension(url.pathExtension)

        if let backgroundUrl = scene.backgroundUrl {
            try? FileManager.default.removeItem(at: backgroundUrl)
        } else if let backgroundUrl = scene.customModelBackgroundUrl {
            try? FileManager.default.removeItem(at: backgroundUrl)
        }

        try? FileManager.default.copyItem(at: url, to: destUrl)

        if customModel {
            scene.customModelBackgroundUrl = destUrl
        } else {
            scene.backgroundUrl = destUrl

        }

        savedScene = scene
        showImmersiveSpace = true
    }

    func addEntity(url: URL, name: String) {
        Task {
            print("opening url", url)
            let scene = savedScene ?? newScene()

            try? FileManager.default.createDirectory(at: scene.sceneUrl, withIntermediateDirectories: true)

            let destUrl = scene.sceneUrl.appending(path: UUID().uuidString).appendingPathExtension("usdz")

            try? FileManager.default.copyItem(at: url, to: destUrl)

            if let entity = try? await Entity(contentsOf: destUrl) {
                DispatchQueue.main.async {
                    let modelData = ModelData(url: destUrl, entity: entity)
                    modelData.name = name
                    entity.name = name
                    //                                self.models.append(modelData)


                    let newModel = scene.addModel(modelData)

                    context.insert(newModel)
                    try? context.save()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {

                        savedScene = scene


                    }
                }
            }
        }

    }

    func newScene() -> SavedScene {

        let currentNameIdx = UserDefaults.standard.integer(forKey: "currentNameIdx")

        let scene = SavedScene(name: "Scene \(currentNameIdx + 1)")

        UserDefaults.standard.setValue(currentNameIdx + 1, forKey: "currentNameIdx")

        context.insert(scene)
        try! context.save()

        return scene
    }

    @State var modelGroups = [ModelGroup<PublicModel>]()
    
    var modelView: some View {
//        NavigationStack {
    
         AssetListView(title: "Add a model", assets: publicModels, collections: modelGroups, tapAction: { model in

                if let url = model.localUrl {
                    addEntity(url: url, name: model.name)
                }

            }, toolbarContent: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        pickingBackground = false
                        showFilePicker = true
                    }, label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("From Files")
                        }
                    })
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        findMoreModels = true
                    }, label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Find More")
                        }
                    })
                }
            }, refreshAction: {
                Task {
                    Cloud.publicModels = []
                    publicModels = await Cloud.getPublicVideos()
                }
            })
         .onChange(of: publicModels.count) { oldValue, newValue in
             var collections = Cloud.collections.map { collection in
                 
                 let models = collection.displayName == "All" ? publicModels : publicModels.filter({ asset in
                     asset.collections.contains(collection.name)
                 }).sorted(by: { l, r in
                     l.name < r.name
                 })
                 return ModelGroup(collection: collection, models: models)
             }
     
         let all = ModelCollection(name: "All", displayName: "All")
         collections.insert(ModelGroup(collection: all, models: publicModels), at: 0)
         modelGroups = collections
         }

//        }
        
    }

    var environmentView: some View {
//        NavigationStack {
            VStack {
                AssetListView(title: "Set an environment", assets: environments, collections: nil, tapAction: { model in
                    
                    if let url = model.localUrl {
                        Task {
                            
                            if !model.isVideo {
                                self.setBackground(url: url, customModel: model.isCustomModel)
                                self.showImmersiveSpace = true
                                self.immersionStyle = ProgressiveImmersionStyle()
                            }
                            
                            
                        }
                    }
                }, toolbarContent: {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            pickingBackground = true
                            showFilePicker = true
                        }, label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("From Files")
                            }
                        })
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            findMoreEnvironments = true
                        }, label: {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("More Info")
                            }
                        })
                    }
                    
                    if self.backgroundUrl != nil {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                Task {
                                    savedScene?.backgroundUrl = nil
                                    self.immersionStyle = MixedImmersionStyle()
                                }
                            }, label: {
                                Text("Remove Environment")
                            })
                        }
                    }
                }
                ) {
                    Task {
                        environments = await Cloud.getPublicEnvironments()
                    }
                }
                
            }
        }
//    }
}

struct AboutView : View {
    
    var body : some View {
        
        VStack {
            Text("The Models App").font(.headline)
            
            
        }
        
    }
    
}

struct ScenesView: View {

    @Query(sort: [SortDescriptor(\SavedScene.lastUpdated, order: .reverse)]) var scenes: [SavedScene]

    @Binding var selectedScene: SavedScene?

    @Environment(\.editMode) private var editMode

    @Environment(\.modelContext) private var context

    @State var showDeleteAlert = false
    @State var itemsToDelete: IndexSet? = nil

    func getDataBinding() -> Binding<[SavedScene]> {
        return .init {
            return scenes
        } set: { newScenes in
            let diff = newScenes.difference(from: scenes)
            diff.forEach { change in
                switch change {
                case .remove(_, let scene, _):
                    guard scene != selectedScene else {
                        return
                    }

                    try? FileManager.default.removeItem(at: scene.sceneUrl)
                    try? context.transaction {
                        context.delete(scene)
                    }

                    break
                default: break
                }
            }
        }
    }


    var body: some View {
        NavigationStack {
            List(getDataBinding(), editActions: [.delete], selection: $selectedScene) { $scene in
//                ForEach(scenes) { scene in
                VStack(alignment: .leading) {
                    Text(scene.name ?? "")
                        .font(.title)
                    Text("\(scene.models.count) \((scene.models.count) > 1 || scene.models.count == 0 ? "models" : "model")")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Last updated \(scene.lastUpdated.formatted())")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
                .deleteDisabled(selectedScene == scene)
                .tag(scene)
//                }
//                .onDelete { indexSet in
//                    indexSet.forEach {
//                        let scene = scenes[$0]
//                        guard scene != selectedScene else { return }
//
//                        try? FileManager.default.removeItem(at: scene.sceneUrl)
//                        try? context.transaction {
//                            context.delete(scene)
//                        }
//                    }
//                }
            }
            .listStyle(InsetListStyle())
            //            .toolbar { // Assumes embedding this view in a NavigationView.
            //                EditButton()
            //            }
            .navigationTitle("Saved Scenes")
        }
    }
}

struct ModelGroup<T>: Identifiable, Hashable where T: PublicAsset {
    var id: String {
        collection.name
    }
    
    static func == (lhs: ModelGroup<T>, rhs: ModelGroup<T>) -> Bool {
        lhs.collection == rhs.collection
    }
    
    let collection: ModelCollection
    let models: [T]
    
    init(collection: ModelCollection, models: [T]) {
        self.collection = collection
        self.models = models
    }
    
    var hashValue: Int {
        collection.name.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(collection.name)
    }
}

struct AssetListView<T, C>: View where T: PublicAsset, C: ToolbarContent {



    let title: String
    let assets: [T]
    let collections: [ModelGroup<T>]?
    let tapAction: (T) -> Void
    let toolbarContent: () -> C
    let refreshAction: () -> Void
    
    init(title: String, assets: [T], collections: [ModelGroup<T>]?, tapAction: @escaping (T) -> Void, @ToolbarContentBuilder toolbarContent:  @escaping (() -> C), refreshAction: @escaping () -> Void) {
        self.title = title
        self.assets = assets
        self.tapAction = tapAction
        self.toolbarContent = toolbarContent
        self.refreshAction = refreshAction
        self.collections = collections
        
        _selectedCollection.wrappedValue = collections?.first
    }

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

//    @State var collections = [ModelGroup]()

    @State var selectedCollection: ModelGroup<T>?

    func content(models: [T]) -> some View {
        //            ZStack {
                        ScrollView {
                            LazyVGrid(columns: columns, content: {
                                ForEach(models) { asset in
                                    ModelItemView(model: asset, tapAction: tapAction)
                                }
                            })
                        }
                        .padding()

                        .refreshable {
                            refreshAction()
                        }
                        
                        .overlay {
                            if (assets.count < 1) {
                                ProgressView()
                                    .zIndex(1)
                            }
                        }
        //            }
                    .navigationTitle(title)
                    .toolbar(content: toolbarContent)
                    .padding(.bottom, 30)

    }
    
    var body: some View {
            if let collections = collections {
                NavigationSplitView {
                    
                    List(collections, selection: $selectedCollection) { group in
                        Text(group.collection.displayName)
                            .tag(group)
                    }
                    .navigationSplitViewColumnWidth(150)
                    
                } detail: {
                    
                    content(models: selectedCollection?.models ?? [])
                        .onAppear {
                            if self.selectedCollection == nil {
                                self.selectedCollection = self.collections?.first
                            }
                        }
                        .onChange(of: collections.count) { oldValue, newValue in
                            self.selectedCollection = self.collections?.first

                        }
                }
            } else {
                NavigationStack {
                    content(models: assets)
                }
            }

    }

}


struct ModelItemView<T>: View where T: PublicAsset {

    let size = CGSize(width: 150, height: 150)

    @Bindable var model: T

    let tapAction: (T) -> Void

    @State var downloadProgress: Double = 0
    @State var downloading = false

    @State var bounce = false

    var body: some View {
        VStack(spacing: 0) {
            AsyncImage(url: model.thumbnailUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    //                    .frame(depth: 20)
                    .clipped()

            } placeholder: {
                ProgressView()
            }
            .frame(height: size.height)

            .opacity(model.localUrl == nil || downloading ? 0.7 : 1)
            .overlay {
                if downloading {
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(.circular)
                        .frame(width: 50, height: 50)
                } else {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            if model.localUrl == nil {
                                Image(systemName: "arrow.down.circle.dotted")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .frame(depth: 10)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    .opacity(0.8)
                    .padding()
                }
            }
            .background(.quinary)

            Text(model.name)
                .font(.caption)
                .frame(depth: 20)
                //                    .shadow(radius: 1)
                .padding()
                .containerRelativeFrame(.horizontal)
                .background(.thinMaterial)
                .background(.tertiary)

        }
        .frame(minWidth: size.width)
        //        .glassBackgroundEffect()
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 8))
        //        .glassBackgroundEffect(in: Rectangle())

        .contentShape([.hoverEffect, .interaction], RoundedRectangle(cornerRadius: 8))
        .hoverEffect(.automatic)
        .phaseAnimator([false, true], trigger: bounce) { content, phase in
            content.scaleEffect(x: phase ? 0.95 : 1, y: phase ? 0.95 : 1)
        } animation: { phase in
            .bouncy(duration: 0.3, extraBounce: 0.3)
        }

        .onTapGesture {
            guard !downloading else {
                return
            }


            bounce.toggle()

            Task {
                if let _ = model.localUrl {
                    tapAction(model)
                } else {

                    self.downloading = true
                    Cloud.downloadAsset(for: model) { progress in
                        print("progress: \(progress)")

                        self.downloadProgress = progress
                    } completionBlock: { result in
                        self.downloading = false

                        switch result {
                        case .failure(let error):
                            print(error)
                        case .success(_):
                            tapAction(model)
                        }
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


struct MockPublicModel: ModelPresentable {
    var id: String

    var title: String

    var thumbnailUrl: URL?

    var url: URL?


    init(title: String, thumbnailUrl: URL? = nil, url: URL? = nil) {
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.url = url
        self.id = title
    }

}

#Preview {

    struct Preview: View {
        let mainWindowSize: CGSize = .init(width: 1280, height: 800)

        @State var savedScene: SavedScene? = SavedScene()
        @State var modes = [ModelData(url: Bundle.main.url(forResource: "model", withExtension: "usdz")!)]
        @State var background: URL? = nil
        @State var selectedModel: Int? = nil
        @State var immersion: any ImmersionStyle = MixedImmersionStyle()
        @State var showImmersive = false
        @State var hasChanges = false
        var body: some View {
            ContentView(savedScene: $savedScene, hasUnsavedChanges: $hasChanges, models: $modes, selectedModel: $selectedModel, immersionStyle: $immersion, showImmersiveSpace: $showImmersive)
                .frame(width: mainWindowSize.width, height: mainWindowSize.height)
                .glassBackgroundEffect()
        }
    }

    return Preview()
}


