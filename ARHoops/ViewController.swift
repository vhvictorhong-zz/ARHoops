//
//  ViewController.swift
//  ARHoops
//
//  Created by Victor Hong on 22/12/2017.
//  Copyright © 2017 Victor Hong. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var planeDetectedLabel: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    var basketAdded: Bool {
        return self.sceneView.scene.rootNode.childNode(withName: "Basketball", recursively: false) != nil
    }
    var power: Float = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Override touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if self.basketAdded {
            guard let pointOfView = self.sceneView.pointOfView else {return}
            self.power = 10
            let transform = pointOfView.transform
            let location = SCNVector3(transform.m41, transform.m42, transform.m43)
            let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
            let position = location + orientation
            let ballNode = SCNNode(geometry: SCNSphere(radius: 0.3))
            ballNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "ball")
            ballNode.position = position
            let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
            ballNode.physicsBody = body
            ballNode.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true)
            self.sceneView.scene.rootNode.addChildNode(ballNode)
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        if !hitTestResult.isEmpty {
            self.addBasket(hitTestResult: hitTestResult.first!)
        }
        
    }
    
    func addBasket(hitTestResult: ARHitTestResult) {
        
        let basketScene = SCNScene(named: "Basketball.scnassets/Basketball.scn")
        let basketNode = basketScene?.rootNode.childNode(withName: "Basketball", recursively: false)
        let positionOfPlane = hitTestResult.worldTransform.columns.3
        let xPosition = positionOfPlane.x
        let yPosition = positionOfPlane.y
        let zPosition = positionOfPlane.z
        basketNode?.position = SCNVector3(xPosition, yPosition, zPosition)
        basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        self.sceneView.scene.rootNode.addChildNode(basketNode!)
        
    }

    //MARK: ARSCN View Delegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetectedLabel.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.planeDetectedLabel.isHidden = true
        }
    }

}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
