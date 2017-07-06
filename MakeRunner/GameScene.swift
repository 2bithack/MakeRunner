//
//  GameScene.swift
//  MakeRunner
//
//  Created by enzo bot on 5/2/17.
//  Copyright © 2017 madJOKERstudios. All rights reserved.
//

import SpriteKit
import GameplayKit
import Foundation
import CoreMotion

let GameMessageName = "gameMessage"


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var diamondCount: Int = 0
    var diamondLabel: SKLabelNode?
    var minutesLabel2: SKLabelNode?
    var secondsLabel2: SKLabelNode?
    var collectedTitle: SKLabelNode?
    var bestTitle: SKLabelNode?
    var diamondTitle: SKSpriteNode?
    var totalDiamondsLabel: SKLabelNode?
    var colonTitle: SKLabelNode?

    var bestTime : Double {
        get{
            if let time = UserDefaults.standard.object(forKey: "bestTime") as? Int{
                return Double(time)
            }
            return 0
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "bestTime")
            UserDefaults.standard.synchronize()
        }
    }
    
    var totalDiamonds : Int {
        get{
            if let diamonds = UserDefaults.standard.object(forKey: "totalDiamonds") as? Int{
                return diamonds
            }
            return 0
        }
        set{
            UserDefaults.standard.set(newValue, forKey: "totalDiamonds")
            UserDefaults.standard.synchronize()
        }
    }
    
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)])
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        diamondLabel = self.childNode(withName: "diamondLabel") as? SKLabelNode
        minutesLabel2 = self.childNode(withName: "minutesLabel2") as? SKLabelNode
        secondsLabel2 = self.childNode(withName: "secondsLabel2") as? SKLabelNode
        bestTitle = self.childNode(withName: "bestTitle") as? SKLabelNode
        diamondTitle = self.childNode(withName: "diamondTitle") as? SKSpriteNode
        totalDiamondsLabel = self.childNode(withName: "totalDiamondsLabel") as? SKLabelNode
        collectedTitle = self.childNode(withName: "collectedTitle") as? SKLabelNode
        colonTitle = self.childNode(withName: "colonTitle") as? SKLabelNode

        totalDiamondsLabel?.text = String(totalDiamonds)
        formatTime()
        
        let gameMessage = SKSpriteNode(imageNamed: "START2")
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)
        addChild(gameMessage)
        
        gameState.enter(WaitingForTap.self)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(Playing.self)
            formatTime()
            
        case is Playing:
            diamondCount = 0
            
        case is GameOver:
            let newScene = GameScene(fileNamed:"GameScene")
            newScene!.scaleMode = .aspectFit
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
            
        default:
            break
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        /* Get references to bodies involved in collision */
        let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        let scale = SKAction.scale(to: 0, duration: 0.1)
        
        /* collisions for hero vs holes, walls and diamonds */
        if nodeA.name == "center" && nodeB.name == "hero" || nodeB.name == "center" && nodeA.name == "hero" {
            let move = SKAction.applyForce(CGVector(dx:0,dy:100), duration: 0.1)
            let death = SKAction.group([move, scale])
            self.childNode(withName: "hero")!.run(death)
            self.gameState.enter(GameOver.self)
        } else if nodeA.name == "fallL" && nodeB.name == "hero" || nodeB.name == "fallL" && nodeA.name == "hero" {
            let move = SKAction.applyForce(CGVector(dx:-100,dy:0), duration: 0.1)
            let death = SKAction.group([move, scale])
            self.childNode(withName: "hero")!.run(death)
            self.gameState.enter(GameOver.self)
        } else if nodeA.name == "fallR" && nodeB.name == "hero" || nodeB.name == "fallR" && nodeA.name == "hero" {
            let move = SKAction.applyForce(CGVector(dx:100,dy:0), duration: 0.1)
            let death = SKAction.group([move, scale])
            self.childNode(withName: "hero")!.run(death)
            self.gameState.enter(GameOver.self)
        } else if nodeA.name == "diamond" && nodeB.name == "hero" || nodeB.name == "diamond" && nodeA.name == "hero" {
            if nodeA.name == "diamond" {
                nodeA.parent!.parent!.removeFromParent()
            }
            else {
                nodeB.parent!.parent!.removeFromParent()
            }
            diamondCount += 1
            diamondLabel?.text = String(diamondCount)
            totalDiamonds += 1
        }
    }
    
    func formatTime() {
        
        // Calculate minutes
        let minutes = UInt16(bestTime / 60.0)
        //bestTime -= (CFTimeInterval(minutes) * 60)
        
        // Calculate seconds
        let seconds = UInt8(bestTime) - UInt8(minutes)*60
        //bestTime -= CFTimeInterval(seconds)
        
        // Format time vars with leading zero
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        
        // Add time vars to relevant labels
        minutesLabel2?.text = strMinutes
        secondsLabel2?.text = strSeconds
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        // TODO: define lastupdateTime
        // TODO: deltaTime = currentTime - lastUpdateTime
        gameState.update(deltaTime: currentTime)
        
       
    }
}
