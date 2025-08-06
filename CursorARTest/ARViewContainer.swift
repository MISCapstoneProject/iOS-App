//
//  ARViewContainer.swift
//  CursorARTest
//
//  Created by Bear on 2025/6/25.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var peopleStore: PeopleStore

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        print("支援 ARBodyTracking 嗎？", ARBodyTrackingConfiguration.isSupported)
        if ARBodyTrackingConfiguration.isSupported {
            let config = ARBodyTrackingConfiguration()
            config.planeDetection = [.horizontal, .vertical]
            arView.session.run(config)
        }
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView
        context.coordinator.peopleStore = peopleStore
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARSessionDelegate {
        var peopleStore: PeopleStore?
        var peopleAnchorIDs: [UUID: Entity] = [:]
        var arView: ARView!

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            var detectedPeople: [CGPoint] = []
            print("📦 有 anchor 更新了：\(anchors.count)")
            for anchor in anchors {
                if let body = anchor as? ARBodyAnchor {
                    print("✅ 偵測到人體：\(body.transform.columns.3)")
                } else {
                    print("❎ 偵測到其他 anchor：\(type(of: anchor))")
                }
            }

            for anchor in anchors {
                if let bodyAnchor = anchor as? ARBodyAnchor {
                    let position = bodyAnchor.transform.columns.3
                    detectedPeople.append(CGPoint(x: CGFloat(position.x), y: CGFloat(position.z)))

                    // 新增/更新 3D 文字標籤
                    let anchorEntity = AnchorEntity(world: [position.x, position.y + 1.8, position.z])
                    let textMesh = MeshResource.generateText("People", extrusionDepth: 0.01, font: .systemFont(ofSize: 0.1), containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping)
                    let material = SimpleMaterial(color: .red, isMetallic: false)
                    let textEntity = ModelEntity(mesh: textMesh, materials: [material])
                    anchorEntity.addChild(textEntity)
                    arView.scene.addAnchor(anchorEntity)
                }
            }
            DispatchQueue.main.async {
                self.peopleStore?.people = detectedPeople
            }
        }
    }
} 