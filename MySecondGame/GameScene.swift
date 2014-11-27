//
//  GameScene.swift
//  MySecondGame
//
//  Created by STEFAN JOSTEN on 23.10.14.
//  Copyright (c) 2014 Stefan. All rights reserved.
//

import SpriteKit

let collisionBulletCategory: UInt32  = 0x1 << 0
let collisionHeroCategory: UInt32    = 0x1 << 1

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Global sprite properties
    var heroSprite = SKSpriteNode(imageNamed:"Spaceship")
    var invisibleControllerSprite = SKSpriteNode()
    var enemySprites = EnemySpriteController()
    
    /// HUD global properties
    var lifeNodes : [SKSpriteNode] = []
    var remainingLifes = 3
    var scoreNode = SKLabelNode()
    var score = 0
    var gamePaused = false
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
       
        self.backgroundColor = UIColor.blackColor()
        
        // Create the hero sprite and place it in the middle of the screen
        heroSprite.xScale = 0.10
        heroSprite.yScale = 0.10
        heroSprite.position = CGPointMake(self.frame.width/2, self.frame.height/2)
        
        // Add physics body for collision detection
        heroSprite.physicsBody?.dynamic = true
        heroSprite.physicsBody = SKPhysicsBody(texture: heroSprite.texture, size: heroSprite.size)
        heroSprite.physicsBody?.affectedByGravity = false
        heroSprite.physicsBody?.categoryBitMask = collisionHeroCategory
        heroSprite.physicsBody?.contactTestBitMask = collisionBulletCategory
        heroSprite.physicsBody?.collisionBitMask = 0x0
       
        
        self.addChild(heroSprite)
        
        // Define invisible sprite for rotating and steering behavior without trigonometry
        invisibleControllerSprite.size = CGSizeMake(0, 0)
        self.addChild(invisibleControllerSprite)
        
        // Define Constraint for the orientation behavior
        let rangeForOrientation = SKRange(constantValue: CGFloat(M_2_PI*7))
        heroSprite.constraints = [SKConstraint.orientToNode(invisibleControllerSprite, offset: rangeForOrientation)]
        
        // Add enemy sprites
        for(var i=0; i<3;i++){
            self.addChild(enemySprites.spawnEnemy(heroSprite))
        }
        
        // Add HUD
        createHUD()
        
        // Handle collisions
        self.physicsWorld.contactDelegate = self
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            var location = touch.locationInNode(self)
            var node = self.nodeAtPoint(location)
            if (node.name == "PauseButton") || (node.name == "PauseButtonContainer") {
                showPauseAlert()
            } else {
       
                // Determine the new position for the invisible sprite:
                // The calculation is needed to ensure the positions of both sprites
                // are nearly the same, but different. Otherwise the hero sprite rotates
                // back to it's original orientation after reaching the location of
                // the invisible sprite
                var xOffset:CGFloat = 1.0
                var yOffset:CGFloat = 1.0
                if location.x>heroSprite.position.x {
                    xOffset = -1.0
                }
                if location.y>heroSprite.position.y {
                    yOffset = -1.0
                }
            
                // Create an action to move the invisibleControllerSprite.
                // This will cause automatic orientation changes for the hero sprite
                let actionMoveInvisibleNode = SKAction.moveTo(CGPointMake(location.x - xOffset, location.y - yOffset), duration: 0.2)
                invisibleControllerSprite.runAction(actionMoveInvisibleNode)
            
                // Create an action to move the hero sprite to the touch location
                let actionMove = SKAction.moveTo(location, duration: 1)
                heroSprite.runAction(actionMove)
            }
        }
    }
    
    // Show Pause Alert
    func showPauseAlert() {
        self.gamePaused = true
        var alert = UIAlertController(title: "Pause", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Default)  { _ in
            self.gamePaused = false
            })
        self.view?.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }

    
    func createHUD() {
        
        // Create a root node with black background to position and group the HUD elemets
        // HUD size is relative to the screen resolution to handle iPad and iPhone screens
        var hud = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(self.size.width, self.size.height*0.05))
        hud.anchorPoint=CGPointMake(0, 0)
        hud.position = CGPointMake(0, self.size.height-hud.size.height)
        self.addChild(hud)
        
        // Display the remaining lifes
        // Add icons to display the remaining lifes
        // Reuse the Spaceship image: Scale and position releative to the HUD size
        let lifeSize = CGSizeMake(hud.size.height-10, hud.size.height-10)
        for(var i = 0; i<self.remainingLifes; i++) {
            var tmpNode = SKSpriteNode(imageNamed: "Spaceship")
            lifeNodes.append(tmpNode)
            tmpNode.size = lifeSize
            tmpNode.position=CGPointMake(tmpNode.size.width * 1.3 * (1.0 + CGFloat(i)), (hud.size.height-5)/2)
            hud.addChild(tmpNode)
        }
        
        // Pause button container and label
        // Needed to increase the touchable area
        // Names will be used to identify these elements in the touch handler
        var pauseContainer = SKSpriteNode()
        pauseContainer.position = CGPointMake(hud.size.width/1.5, 1)
        pauseContainer.size = CGSizeMake(hud.size.height*3, hud.size.height*2)
        pauseContainer.name = "PauseButtonContainer"
        hud.addChild(pauseContainer)
        
        var pauseButton = SKLabelNode()
        pauseButton.position = CGPointMake(hud.size.width/1.5, 1)
        pauseButton.text="I I"
        pauseButton.fontSize=hud.size.height
        pauseButton.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        pauseButton.name="PauseButton"
        hud.addChild(pauseButton)
        
        // Display the current score
        self.score = 0
        self.scoreNode.position = CGPointMake(hud.size.width-hud.size.width * 0.1, 1)
        self.scoreNode.text = "0"
        self.scoreNode.fontSize = hud.size.height
        hud.addChild(self.scoreNode)
        
    }
   
    func didBeginContact(contact: SKPhysicsContact) {
        if !self.gamePaused {
        
        }
    }
    
    var _dLastShootTime: CFTimeInterval = 1
    
    override func update(currentTime: CFTimeInterval) {

        if !self.gamePaused {
            
            if currentTime - _dLastShootTime >= 1 {
                enemySprites.shoot(heroSprite)
                _dLastShootTime=currentTime
            }
        }
    }

}
