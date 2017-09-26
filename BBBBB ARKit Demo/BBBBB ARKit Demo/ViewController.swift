//
//  ViewController.swift
//  BBBBB ARKit Demo
//
//  Created by Hahn.Chan on 25/09/2017.
//  Copyright © 2017 Hahn Chan. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

struct CollisionCategory {
    static let plane = 1 << 0
    static let box = 1 << 1
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var treeNode: SCNNode?
    var planeNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/Lowpoly_tree_sample.dae")!
//        treeNode = scene.rootNode.childNode(withName: "Tree_lp_11", recursively: true)
//        treeNode?.position.z = -1

        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.isLightEstimationEnabled = true

        // Run the view's session
        sceneView.session.run(configuration)
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("```````````plane detected````````````")
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeBox = SCNBox.init(width: CGFloat(planeAnchor.extent.x),
                                   height: 0,
                                   length: CGFloat(planeAnchor.extent.z),
                                   chamferRadius: 0)
        planeBox.firstMaterial?.diffuse.contents = UIColor.red
        
        planeNode = SCNNode.init(geometry: planeBox)
        planeNode?.position = SCNVector3.init(x: planeAnchor.center.x,
                                             y: 0,
                                             z: planeAnchor.center.z)
        planeNode?.physicsBody = SCNPhysicsBody.init(type: .kinematic, shape: SCNPhysicsShape.init(geometry: planeBox, options: nil))
        planeNode?.physicsBody?.categoryBitMask = CollisionCategory.plane
        planeNode?.physicsBody?.contactTestBitMask = CollisionCategory.box
        
        node.addChildNode(planeNode!)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        print("```````````plane updated````````````")
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        planeNode?.geometry = SCNBox.init(width: CGFloat(planeAnchor.extent.x),
                                          height: 0,
                                          length: CGFloat(planeAnchor.extent.z),
                                          chamferRadius: 0)
        planeNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        planeNode?.position = SCNVector3.init(x: planeAnchor.center.x,
                                              y: 0,
                                              z: planeAnchor.center.z)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.existingPlaneUsingExtent])
        guard let hitFeature = results.last else { return }
        insertGeometry(hitResult: hitFeature)
//        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
//        let hitPosition = SCNVector3.init(x: hitTransform.m41,
//                                          y: hitTransform.m42,
//                                          z: hitTransform.m43)
//        let treeClone = treeNode!.clone()
//        treeClone.position = hitPosition
//        sceneView.scene.rootNode.addChildNode(treeClone)
    }
    
    func insertGeometry(hitResult: ARHitTestResult) {
        let dimension: CGFloat = 0.1
        let cube = SCNBox.init(width: dimension,
                               height: dimension,
                               length: dimension,
                               chamferRadius: 0)
        let node = SCNNode.init(geometry: cube)
        node.physicsBody = SCNPhysicsBody.init(type: .dynamic,
                                               shape: SCNPhysicsShape.init(geometry: cube,
                                                                           options: nil))
        node.physicsBody?.mass = 2.0
        node.physicsBody?.categoryBitMask = CollisionCategory.box
        
        let insertionYOffset: Float = 0.5
        node.position = SCNVector3.init(x: hitResult.worldTransform.columns.3.x,
                                        y: hitResult.worldTransform.columns.3.y + insertionYOffset,
                                        z: hitResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(node)
    }
}

extension ViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let mask = contact.nodeA.categoryBitMask | contact.nodeB.categoryBitMask
        
        if mask == (CollisionCategory.plane | CollisionCategory.box) {
            if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.plane {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
}
