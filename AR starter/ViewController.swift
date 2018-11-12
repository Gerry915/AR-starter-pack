//
//  ViewController.swift
//  AR starter pack
//
//  Created by Gerry Gao on 2/8/18.
//  Copyright © 2018 Gerry Gao. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    var flag = false
    var animations = [String: CAAnimation]()
    var idle:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.layer.cornerRadius = 10
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.delegate = self
        setupCamera()
        sceneView.showsStatistics = false
        self.sceneView.automaticallyUpdatesLighting = false
        self.sceneView.autoenablesDefaultLighting = false
        UIApplication.shared.isIdleTimerDisabled = true
        self.registerGestureRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = false
        configuration.isAutoFocusEnabled = true
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "photos", bundle: Bundle.main) else { return }
        configuration.detectionImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: [.estimatedHorizontalPlane, .existingPlaneUsingExtent]).first
        if  hitTest != nil && flag == false{
            flag = true
            print("touched plane")
            self.additem(hitTestResult: hitTest!)
        }else {
            print("no match")
        }
    }
    
    func additem(hitTestResult: ARHitTestResult) {
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        /*
        //ADD YOUR SCN FILE HERE
        */
        let scene = SCNScene(named: "art.scnassets/default.scn")!
        let instanceNode = SCNNode()
        for child in scene.rootNode.childNodes {
            instanceNode.addChildNode(child)
        }
        instanceNode.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        self.sceneView.scene.rootNode.addChildNode(instanceNode)
        shutDownConfig()
    }
    
    func shutDownConfig () {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = []
        sceneView.session.run(config)
    }
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    //FOR IMAGE TRACING
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        if let imageAnchor = anchor as? ARImageAnchor {
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.1)
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            /*
            //ADD YOUR SCN FILE HERE
            */
            let instance = SCNScene(named: "art.scnassets/default.scn")!
            let instanceNode = SCNNode()
            for child in instance.rootNode.childNodes {
                instanceNode.addChildNode(child)
            }
            instanceNode.position = SCNVector3(x: 0, y: 0, z: 0)
            instanceNode.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
            instanceNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 90.degreesToRadians)
            planeNode.addChildNode(instanceNode)
            
            node.addChildNode(planeNode)
        }

        return node
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        statusLabel.text = "Session failed: \(error.localizedDescription)"
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move the device around to detect horizontal surfaces."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        statusLabel.text = message
        statusLabel.isHidden = message.isEmpty
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180 }
}
