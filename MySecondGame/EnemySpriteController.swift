//
//  EnemySpriteController.swift
//  MySecondGame
//
//  Created by STEFAN on 09.11.14.
//  Copyright (c) 2014 Stefan. All rights reserved.
//

import Foundation
import SpriteKit

// Controller class for:
// - creating/destroying enemies, 
// - shooting
// - animitaions
class EnemySpriteController {
    var enemySprites: [SKSpriteNode] = []

    // Return a new enemy sprite which follows the targetSprite node
    func spawnEnemy(targetSprite: SKNode) -> SKSpriteNode {

        // create a new enemy sprite
        let newEnemy = SKSpriteNode(imageNamed:"Spaceship")
        enemySprites.append(newEnemy)
        newEnemy.xScale = 0.08
        newEnemy.yScale = 0.08
        newEnemy.color = UIColor.redColor()
        newEnemy.colorBlendFactor=0.6
        
        // position new sprite at a random position on the screen
        var sizeRect = UIScreen.mainScreen().applicationFrame;
        var posX = arc4random_uniform(UInt32(sizeRect.size.width))
        var posY = arc4random_uniform(UInt32(sizeRect.size.height))
        newEnemy.position = CGPoint(x: CGFloat(posX), y: CGFloat(posY))
        
        // Define Constraints for orientation/targeting behavior
        let i = enemySprites.count-1
        let rangeForOrientation = SKRange(constantValue:CGFloat(M_2_PI*7))
        let orientConstraint = SKConstraint.orientToNode(targetSprite, offset: rangeForOrientation)
        let rangeToSprite = SKRange(lowerLimit: 80, upperLimit: 90)
        var distanceConstraint: SKConstraint
  
        // First enemy has to follow spriteToFollow, second enemy has to follow first enemy, ...
        if enemySprites.count-1 == 0 {
            distanceConstraint = SKConstraint.distance(rangeToSprite, toNode: targetSprite)
        } else {
            distanceConstraint = SKConstraint.distance(rangeToSprite, toNode: enemySprites[i-1])
        }
        newEnemy.constraints = [orientConstraint, distanceConstraint]
        
        return newEnemy
    }
    
    // Shoot in direction of spriteToShoot
    func shoot(targetSprite: SKNode) {
        
        for enemy in enemySprites {
            
            // Create the bullet sprite
            let bullet = SKSpriteNode()
            bullet.color = UIColor.greenColor()
            bullet.size = CGSize(width: 5,height: 5)
            bullet.position = CGPointMake(enemy.position.x, enemy.position.y)
            targetSprite.parent?.addChild(bullet)
            
            // Add physics body for collision detection
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.frame.size)
            bullet.physicsBody?.dynamic = true
            bullet.physicsBody?.affectedByGravity = false
            bullet.physicsBody?.categoryBitMask = collisionBulletCategory
            bullet.physicsBody?.contactTestBitMask = collisionHeroCategory
            bullet.physicsBody?.collisionBitMask = 0x0;
            
            // Determine vector to targetSprite
            let vector = CGVectorMake((targetSprite.position.x-enemy.position.x), targetSprite.position.y-enemy.position.y)
            
            // Create the action to move the bullet. Don't forget to remove the bullet!
            let bulletAction = SKAction.sequence([SKAction.repeatAction(SKAction.moveBy(vector, duration: 1), count: 10) ,  SKAction.waitForDuration(30.0/60.0), SKAction.removeFromParent()])
            bullet.runAction(bulletAction)
            
        }
    }

}


