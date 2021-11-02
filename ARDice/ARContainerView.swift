//
//  RealityKitView.swift
//  ARDice
//
//  Created by Philipp on 02.11.21.
//

import SwiftUI
import ARKit
import RealityKit
import FocusEntity

struct ARContainerView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let view = ARView()

        // Start AR session
        let session = view.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.run(config)

        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        view.addSubview(coachingOverlay)

#if DEBUG
        // Set debug options
        //view.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
        view.debugOptions = [.showAnchorOrigins, .showPhysics]
#endif

        // Handle ARSession events via delegate
        context.coordinator.view = view
        session.delegate = context.coordinator


        // Handle taps
        view.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
        )

        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        var focusEntity: FocusEntity?
        var diceEntity: ModelEntity?

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let view = self.view else { return }
            print("Anchor added to the scene: ", anchors)
            self.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
        }

        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }

            if let diceEntity = diceEntity {
                diceEntity.addForce(SIMD3(0, 4, 0), relativeTo: nil)
                let randomRange: ClosedRange<Float> = -0.4...0.4
                diceEntity.addTorque(SIMD3(Float.random(in: randomRange),
                                           Float.random(in: randomRange),
                                           Float.random(in: randomRange)),
                                     relativeTo: nil)
            } else {

                // Create a new anchor to add content to
                let anchor = AnchorEntity()
                view.scene.anchors.append(anchor)

                // Add a dice entity
                let diceEntity = try! Entity.loadModel(named: "Dice")
                diceEntity.scale = .init(0.1, 0.1, 0.1)
                diceEntity.position = focusEntity.position
                let extent = diceEntity.visualBounds(relativeTo: diceEntity).extents.y
                let boxShape = ShapeResource.generateBox(size: [extent, extent, extent])
                diceEntity.collision = CollisionComponent(shapes: [boxShape])
                diceEntity.physicsBody = PhysicsBodyComponent(
                    massProperties: .init(shape: boxShape, mass: 50),
                    material: nil,
                    mode: .dynamic
                )

                anchor.addChild(diceEntity)


                // Create a plane below the dice
                let planeMesh = MeshResource.generatePlane(width: 2, depth: 2)
                let material = SimpleMaterial(color: .init(white: 1.0, alpha: 0.1), isMetallic: false)
                let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
                planeEntity.position = focusEntity.position
                planeEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static)
                planeEntity.collision = CollisionComponent(shapes: [.generateBox(width: 2, height: 0.001, depth: 2)])
                planeEntity.position = focusEntity.position
                anchor.addChild(planeEntity)

                self.diceEntity = diceEntity
            }
        }
    }
}
