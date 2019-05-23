//
//  ViewController.swift
//  Augmented Reality Shop Project
//
//  Created by Andrew Seak on 5/20/19.
//  Copyright © 2019 GLTech. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import AVKit
import SpriteKit

class ViewController: UIViewController, ARSCNViewDelegate {

    //Initialize variables
    @IBOutlet var sceneView: ARSCNView!
    var videoPaused: Bool = false
    var videoAdded: Bool = false
    var videoWasFullscreen: Bool = false
    var videoTimeAfterFullscreen: CMTime?
    var currentVideoReferenceImage: String?
    var videoReferenceImageBeforeFullscreen: String?
    var videoAVPlayer: AVPlayer?
    var videoAVNode: SCNNode?
    var videoAVController: AVPlayerViewController?
    var intTaps: Int32 = 0
    var tapTick: Int32 = 0
    
    //Dictionary for the video paths
    let videoPaths = ["maxresdefault": "Waterfall",
                      "referenceimage2": "Network",
                      "lamborghini": "AutoTech",
                      "schoolimage": "recruitment",
                      "ramzi": "AutoCollision"]
    
    //Dictionary for the shop names
    let shopNames = ["maxresdefault": "Programming and Web Development",
                     "referenceimage2": "Engineering",
                     "lamborghini": "Automotive Technology",
                     "schoolimage": "",
                     "ramzi": "Auto Collision"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //UIApplication.shared.isIdleTimerDisabled = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {fatalError("Missing AR Resources")}
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //Function that creates a video node
    func createVideoNode(anchor: ARImageAnchor, didAdd node: SCNNode, videoName: String, text: String) {
        //Create planeNode
        let referenceImage = anchor.referenceImage
        let plane = SCNPlane(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height)
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi/2
        node.addChildNode(planeNode)
        //Create video URL
        var videoURL: URL
        let index = videoName.index(videoName.startIndex, offsetBy: 4)
        let substring = videoName[..<index]
        if (substring == "http") { //Check if its online
            videoURL = NSURL(string: videoName)! as URL
        } else {
            videoURL = Bundle.main.url(forResource: videoName, withExtension: "mp4")!
        }
        //Create video player
        let videoPlayer = AVPlayer(url: videoURL)
        let videoScene = SKScene(size: CGSize(width: 1920, height: 1080))
        //Create video node
        let videoNode = SKVideoNode(avPlayer: videoPlayer)
        videoNode.position = CGPoint(x: videoScene.size.width/2, y: videoScene.size.height/2)
        videoNode.size = videoScene.size
        videoNode.yScale = -1
        videoNode.play()
        //Create text label
        let textLabel = SCNText(string: text, extrusionDepth: 3)
        textLabel.font = UIFont(name: "SignPainter", size: UIFont.labelFontSize)
        textLabel.firstMaterial!.diffuse.contents = UIColor.black
        textLabel.firstMaterial!.specular.contents = UIColor.black
        //Create text node
        let textNode = SCNNode()
        textNode.scale = SCNVector3(x: 0.0015, y: 0.0015, z: 0.0015)
        textNode.geometry = textLabel
        textNode.eulerAngles.x = -.pi/2
        textNode.simdLocalTranslate(by: float3(-(textNode.boundingBox.max.x * 0.0015)/2, Float(referenceImage.physicalSize.height/2) - 0.01, 0))
        
        node.addChildNode(textNode)
        videoScene.addChild(videoNode)
        //Set planeNode geometry material contents to the videoScene
        planeNode.geometry?.firstMaterial?.diffuse.contents = videoScene
        
        videoPlayer.seek(to: CMTime.zero)
        videoPlayer.preventsDisplaySleepDuringVideoPlayback = true
        //print("create")
        videoAVPlayer = videoPlayer
        videoAVNode = node
    }
    
    func fullScreenVideo() {
        DispatchQueue.main.async {
            self.videoAVPlayer!.pause()
            self.videoReferenceImageBeforeFullscreen = self.currentVideoReferenceImage
            self.videoWasFullscreen = true
            self.videoAVController = AVPlayerViewController()
            self.videoAVController!.player = self.videoAVPlayer
            self.videoAVController!.exitsFullScreenWhenPlaybackEnds = true
            self.present(self.videoAVController!, animated: true) {
                self.videoAVController!.player!.play()
            }
        }
    }
    
    func pauseVideo() {
        //print("pause video")
        //Pause video
        if videoAVPlayer != nil {
            if videoPaused {
                videoPaused = false
                videoAVPlayer!.play()
            } else {
                videoPaused = true
                videoAVPlayer!.pause()
            }
        }
    }
    
    //Every millisecond
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else {return}
        //print(videoAVController!.player!)
        if imageAnchor.isTracked {
            currentVideoReferenceImage = imageAnchor.referenceImage.name
            if videoAdded == false { //One video in the scene at a time
                videoAdded = true
                let referenceImage = imageAnchor.referenceImage
                //Get video name and text by image name
                let referencePhoto = referenceImage.name!
                createVideoNode(anchor: imageAnchor, didAdd: node, videoName: videoPaths[referencePhoto]!, text: shopNames[referencePhoto]!)
                
                //only resume time if its the same video
                if (videoWasFullscreen == true) && (referencePhoto == videoReferenceImageBeforeFullscreen) {
                    videoWasFullscreen = false
                    videoAVPlayer?.seek(to: (videoAVController?.player!.currentTime())!)
                }
            }
            //Tap handler
            if (intTaps >= 1) {
                tapTick += 1
            }
            if (tapTick > 20) {
                if (intTaps == 1) {
                    print("single tapped pause video")
                    pauseVideo()
                } else if (intTaps == 2) {
                    print("double tapped fullscreen video")
                    fullScreenVideo()
                }
                tapTick = 0
                intTaps = 0
            }
            //print("tracking")
        } else {
            currentVideoReferenceImage = nil
            //print("not tracking")
            //Reset variables
            intTaps = 0
            tapTick = 0
            videoAdded = false
            videoPaused = false
            if videoAVNode != nil {
                videoAVPlayer!.pause()
                videoAVNode!.enumerateChildNodes() {node,_ in //Optimize app by deleting other nodes
                    node.removeFromParentNode()
                }
                videoAVPlayer = nil
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.view == self.sceneView {
                if videoAdded {
                    intTaps += 1
                    if intTaps >= 1 {
                        tapTick = 0
                    }
                }
            }
        }
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
}
