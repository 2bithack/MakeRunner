//
//  Playing.swift
//  BreakoutSpriteKitTutorial
//
//  Created by Michael Briscoe on 1/16/16.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import SpriteKit
import GameplayKit
import Foundation
import CoreMotion

class Playing: GKState, SKPhysicsContactDelegate {
    unowned let scene: GameScene
    var hero: SKSpriteNode!
    var woodFloor: SKSpriteNode!
    var scrollLayer: SKNode!
    var obstacleLayer: SKNode!
    var variableLayer: SKNode!
    var tilt: SKNode?
    let fixedDelta: CFTimeInterval = 1.0/60.0 //60 fps
    var holeSpawnRate: CFTimeInterval = 0.8
    var holeSpawnTimer: CFTimeInterval = 0
    var diamondTimer: CFTimeInterval = 0
    var gameTimer: CFTimeInterval = 0
    var runTimer: CFTimeInterval = 0
    var startTime: Double = 0.0
    var time: Double = 0.0
    var elapsedTime: Double = 0.0
    var minutesLabel: SKLabelNode?
    var secondsLabel: SKLabelNode?
    var millisecondsLabel: SKLabelNode?
    var timeFlag: Bool = false
    
    let motionManager = CMMotionManager()
    
    var scrollSpeed: CGFloat = 160
    
    var timePlaying: TimeInterval = 0 {
        didSet {
            print(time)
        }
    }
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
        
    }
  
    override func didEnter(from previousState: GKState?) {
        
        print("Did enter PLAYING ******* ")
        
        startTime = Date().timeIntervalSinceReferenceDate

        if previousState is WaitingForTap {
            hero = scene.childNode(withName: "//hero") as! SKSpriteNode
    
        /* Set reference to scroll layer node */
            scrollLayer = scene.childNode(withName: "scrollLayer")
            tilt = scene.childNode(withName: "//tilt")
            minutesLabel = scene.childNode(withName: "minutesLabel") as? SKLabelNode
            secondsLabel = scene.childNode(withName: "secondsLabel") as? SKLabelNode
            millisecondsLabel = scene.childNode(withName: "millisecondsLabel") as? SKLabelNode

            // Start motion manager
            motionManager.startAccelerometerUpdates()
            
            //hide highscore
            scene.minutesLabel2?.isHidden = true
            scene.secondsLabel2?.isHidden = true
            scene.bestTitle?.isHidden = true
            scene.diamondTitle?.isHidden = true
            scene.totalDiamondsLabel?.isHidden = true
            scene.collectedTitle?.isHidden = true
            scene.colonTitle?.isHidden = true


        }
    }
    
    override func willExit(to nextState: GKState) {
        // Stop motion manager
        motionManager.stopAccelerometerUpdates()
        //save time if better than best and add diamonds to totalDiamonds
        gameOverTime()
        scene.formatTime()
        
        //show highscore
        scene.totalDiamondsLabel?.text = String(scene.totalDiamonds)
        scene.minutesLabel2?.isHidden = false
        scene.secondsLabel2?.isHidden = false
        scene.bestTitle?.isHidden = false
        scene.diamondTitle?.isHidden = false
        scene.totalDiamondsLabel?.isHidden = false
        scene.collectedTitle?.isHidden = false
        scene.colonTitle?.isHidden = false
        
    }
    
    func calcTime() {
        // Calculate total time since timer started in seconds
        time = Date().timeIntervalSinceReferenceDate - startTime
        
        // Calculate minutes
        let minutes = UInt8(time / 60.0)
        time -= (CFTimeInterval(minutes) * 60)
        
        // Calculate seconds
        let seconds = UInt8(time)
        time -= CFTimeInterval(seconds)
        
        // Calculate milliseconds
        let milliseconds = UInt8(time * 100)
        
        // Format time vars with leading zero
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        let strMilliseconds = String(format: "%02d", milliseconds)
        
        // Add time vars to relevant labels
        minutesLabel?.text = strMinutes
        secondsLabel?.text = strSeconds
        millisecondsLabel?.text = strMilliseconds

    }
    
    func gameOverTime(){
        elapsedTime = Date().timeIntervalSinceReferenceDate - startTime
         if elapsedTime > scene.bestTime {
                scene.bestTime = elapsedTime
        }
        
    }
    
    func scrollWorld() {
        //world scroll
        scrollLayer.position.y -= scrollSpeed * CGFloat(fixedDelta)
        
        //obstacle scroll
        obstacleLayer = scene.childNode(withName: "obstacleLayer")!
        //variableLayer = scene.childNode(withName: "variableLayer")!
        
        //loop scroll layer nodes
        for ground in scrollLayer.children as! [SKSpriteNode] {
            
            //get ground node position, convert node position to scene space
            let floorPosition = scrollLayer.convert(ground.position, to: scene)
            //let instrucPosition = scrollLayer.convertPoint(ground.position, toNode: self)
            
            //check ground position has left scene
            if floorPosition.y <= -ground.size.height/2 {
                
                if ground == tilt {
                    ground.removeFromParent()
                }
                else {
                    ground.position.y += ground.size.height * 2
                    
                }
            }
        }
    }
    
    func updateObstacles() {
        
        obstacleLayer.position.y -= scrollSpeed * CGFloat(fixedDelta)
        //variableLayer.position.y -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convert(obstacle.position, to: scene)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.y <= -20 {
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
                
            }
            
        }
        //create time condition to start spawn of diamond
        
        if Int(runTimer)%3 == 1 {
            diamondTimer = Double(arc4random_uniform(2) + 1)
        }
        //spawn the diamond at a random x position after
        if diamondTimer > 0 {
            diamondTimer -= fixedDelta
            if diamondTimer < 0 {
                let diamondPath = Bundle.main.path(forResource: "diamond", ofType: "sks")
                let diamondNode = SKReferenceNode (url: URL (fileURLWithPath: diamondPath!))
                let randomDiamondPosition = CGPoint(x: CGFloat.random(min: 40, max: 280), y: 556)
                obstacleLayer.addChild(diamondNode)
                diamondNode.name = "diamond"
                diamondNode.zPosition = 2
                diamondNode.position = scene.convert(randomDiamondPosition, to: obstacleLayer)
            }
        }
        
        if holeSpawnTimer >= holeSpawnRate {
            
            /* Create an array of obstacles */
            let filenames = ["4hole", "3hole", "3holeDbl", "2holeCtr", "3holeLeft", "3holeRight", "3holeCtr"]
            
            // represent the selected obstacle from array
            let filename = filenames[Int(arc4random()) % filenames.count]
            
            let resourcePath = Bundle.main.path(forResource: filename, ofType: "sks")
            let newObstacle = SKReferenceNode (url: URL (fileURLWithPath: resourcePath!))
            obstacleLayer.addChild(newObstacle)
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = scene.convert(CGPoint(x: 0.0, y: 568.0), to: obstacleLayer)
            
            // Reset spawn timer
            holeSpawnTimer = 0
            
        }

    }
    
    override func update(deltaTime seconds: TimeInterval) {
        calcTime()
        scrollWorld()
        updateObstacles()
        holeSpawnTimer += fixedDelta
        runTimer += fixedDelta
        
        //Get Accel data
        if let data = motionManager.accelerometerData {
            //Apply Force
            self.hero.physicsBody?.applyForce(CGVector(dx: 100 * CGFloat(data.acceleration.x), dy: 0))
        }
      
    }
  
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is GameOver.Type
    }
    
  
}
