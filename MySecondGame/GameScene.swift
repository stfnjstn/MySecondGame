//
//  GameScene.swift
//  MySecondGame
//
//  Created by STEFAN on 23.10.14.
//  Copyright (c) 2014 Stefan. All rights reserved.
//

import SpriteKit
import GameKit
import StoreKit

// protocol to inform the delegate (GameViewController) about a game over situation
protocol GameSceneDelegate {
    func gameOver()
}

let collisionBulletCategory: UInt32  = 0x1 << 0
let collisionHeroCategory: UInt32    = 0x1 << 1

class GameScene: SKScene, SKPhysicsContactDelegate, SKPaymentTransactionObserver, SKProductsRequestDelegate  {
    
    let soundAction = SKAction.playSoundFileNamed("Explosion.wav", waitForCompletion: false)
    
    // Global sprite properties
    var heroSprite = SKSpriteNode(imageNamed:"Spaceship")
    var invisibleControllerSprite = SKSpriteNode()
    var enemySprites = EnemySpriteController()
    
    // HUD global properties
    var lifeNodes : [SKSpriteNode] = []
    var remainingLifes = 3
    var scoreNode = SKLabelNode()
    var score : Int64 = 0
    var gamePaused = false
    
    // GameCenter
    var gameCenterDelegate : GameSceneDelegate?
    var gameOver = false
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
       
        self.backgroundColor = UIColor.blackColor()
        
        // Create the hero sprite and place it in the middle of the screen
        heroSprite.xScale = 0.10
        heroSprite.yScale = 0.10
        heroSprite.position = CGPointMake(self.frame.width/2, self.frame.height/2)
        
        // Add physics body for collision detection
        heroSprite.physicsBody?.dynamic = true
        heroSprite.physicsBody = SKPhysicsBody(texture: heroSprite.texture!, size: heroSprite.size)
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
        
        // Add Starfield with 3 emitterNodes for a parallax effect
        // - Stars in top layer: light, fast, big
        // - ...
        // - Stars in back layer: dark, slow, small
        var emitterNode = starfieldEmitter(SKColor.lightGrayColor(), starSpeedY: 50, starsPerSecond: 1, starScaleFactor: 0.2)
        emitterNode.zPosition = -10
        self.addChild(emitterNode)
        
        emitterNode = starfieldEmitter(SKColor.grayColor(), starSpeedY: 30, starsPerSecond: 2, starScaleFactor: 0.1)
        emitterNode.zPosition = -11
        self.addChild(emitterNode)
        
        emitterNode = starfieldEmitter(SKColor.darkGrayColor(), starSpeedY: 15, starsPerSecond: 4, starScaleFactor: 0.05)
        emitterNode.zPosition = -12
        self.addChild(emitterNode)
        
        // In-App Purchase
        initInAppPurchases()
        checkAndActivateGreenShip()
        
    }
    
    // --------------------------
    // ---- particle effects ----
    // --------------------------
    func starfieldEmitter(color: SKColor, starSpeedY: CGFloat, starsPerSecond: CGFloat, starScaleFactor: CGFloat) -> SKEmitterNode {

        // Determine the time a star is visible on screen
        let lifetime =  frame.size.height * UIScreen.mainScreen().scale / starSpeedY
        
        // Create the emitter node
        let emitterNode = SKEmitterNode()
        emitterNode.particleTexture = SKTexture(imageNamed: "StarParticle")
        emitterNode.particleBirthRate = starsPerSecond
        emitterNode.particleColor = SKColor.lightGrayColor()
        emitterNode.particleSpeed = starSpeedY * -1
        emitterNode.particleScale = starScaleFactor
        emitterNode.particleColorBlendFactor = 1
        emitterNode.particleLifetime = lifetime
        
        // Position in the middle at top of the screen
        emitterNode.position = CGPoint(x: frame.size.width/2, y: frame.size.height)
        emitterNode.particlePositionRange = CGVector(dx: frame.size.width, dy: 0)
        
        // Fast forward the effect to start with a filled screen
        emitterNode.advanceSimulationTime(NSTimeInterval(lifetime))
        
        return emitterNode
    }

    func explosion(pos: CGPoint) {
        let emitterNode = SKEmitterNode(fileNamed: "ExplosionParticle.sks")
        emitterNode!.particlePosition = pos
        self.addChild(emitterNode!)
        self.runAction(SKAction.waitForDuration(2), completion: { emitterNode!.removeFromParent() })
    }
    
    // Handle touch events
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            let location = touch.locationInNode(self)
            let node = self.nodeAtPoint(location)
            if (node.name == "PauseButton") || (node.name == "PauseButtonContainer") {
                showPauseAlert()
            } else if (node.name == "PurchaseButton") {
                inAppPurchase()
            } else if (node.name == "InfoButton") {
                UIApplication.sharedApplication().openURL(NSURL(string: "http://stefansdevplayground.blogspot.com/p/tutorials.html")!)
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
        let alert = UIAlertController(title: "Pause", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Default)  { _ in
            self.gamePaused = false
            })
        self.view?.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    func createHUD() {
        
        // Create a root node with black background to position and group the HUD elemets
        // HUD size is relative to the screen resolution to handle iPad and iPhone screens
        let hud = SKSpriteNode(color: UIColor.blackColor(), size: CGSizeMake(self.size.width, self.size.height*0.05))
        hud.anchorPoint=CGPointMake(0, 0)
        hud.position = CGPointMake(0, self.size.height-hud.size.height)
        self.addChild(hud)
        
        // Display the remaining lifes
        // Add icons to display the remaining lifes
        // Reuse the Spaceship image: Scale and position releative to the HUD size
        let lifeSize = CGSizeMake(hud.size.height-10, hud.size.height-10)
        for(var i = 0; i<self.remainingLifes; i++) {
            let tmpNode = SKSpriteNode(imageNamed: "Spaceship")
            lifeNodes.append(tmpNode)
            tmpNode.size = lifeSize
            tmpNode.position=CGPointMake(tmpNode.size.width * 1.3 * (1.0 + CGFloat(i)), (hud.size.height-5)/2)
            hud.addChild(tmpNode)
        }
        
        // Pause button container and label
        // Needed to increase the touchable area
        // Names will be used to identify these elements in the touch handler
        let pauseContainer = SKSpriteNode()
        pauseContainer.position = CGPointMake(hud.size.width/1.5, 1)
        pauseContainer.size = CGSizeMake(hud.size.height*3, hud.size.height*2)
        pauseContainer.name = "PauseButtonContainer"
        hud.addChild(pauseContainer)
        
        let pauseButton = SKLabelNode()
        pauseButton.position = CGPointMake(hud.size.width/1.5, 1)
        pauseButton.text="I I"
        pauseButton.fontSize=hud.size.height
        pauseButton.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        pauseButton.name="PauseButton"
        hud.addChild(pauseButton)
        
        // Add a $ Button for In-App Purchases:
        let purchaseButton = SKLabelNode()
        purchaseButton.position = CGPointMake(hud.size.width/2.5, 1)
        purchaseButton.text="$$$"
        purchaseButton.fontSize=hud.size.height
        purchaseButton.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        purchaseButton.name="PurchaseButton"
        hud.addChild(purchaseButton)
        
        // Display the current score
        self.score = 0
        self.scoreNode.position = CGPointMake(hud.size.width-hud.size.width * 0.1, 1)
        self.scoreNode.text = "0"
        self.scoreNode.fontSize = hud.size.height
        hud.addChild(self.scoreNode)
        
        // Add Info button to show tutorials
        let infoButton = SKLabelNode()
        infoButton.position = CGPointMake(hud.size.width/3, 1)
        infoButton.text="Info"
        infoButton.fontSize=hud.size.height
        infoButton.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Center
        infoButton.name="InfoButton"
        hud.addChild(infoButton)
        
    }
    
    func lifeLost() {
        explosion(self.heroSprite.position)
        
        self.gamePaused = true
        
        
        // Play sound:
        runAction(soundAction)
        
        // remove one life from hud
        if self.remainingLifes>0 {
            self.lifeNodes[remainingLifes-1].alpha=0.0
            self.remainingLifes--;
        }
        
        // check if remaining lifes exists
        if (self.remainingLifes==0) {
            showGameOverAlert()
        }
        
        // Stop movement, fade out, move to center, fade in
        heroSprite.removeAllActions()
        self.heroSprite.runAction(SKAction.fadeOutWithDuration(1) , completion: {
            self.heroSprite.position = CGPointMake(self.size.width/2, self.size.height/2)
            self.heroSprite.runAction(SKAction.fadeInWithDuration(1), completion: {
                self.gamePaused = false
            })
        })
    }
    
    // Game Over
    func showGameOverAlert() {
        self.gameOver = true
        let alert = UIAlertController(title: "Game Over", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default)  { _ in
            
            // restore lifes in HUD
            self.remainingLifes=3
            for(var i = 0; i<3; i++) {
                self.lifeNodes[i].alpha=1.0
            }
            // reset score
            self.addLeaderboardScore(self.score)
            self.score=0
            self.scoreNode.text = String(0)
            
        })
        
        // show alert
        self.view?.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }

    // Game Center integration
    func addLeaderboardScore(score: Int64) {
        let newGCScore = GKScore(leaderboardIdentifier: "MySecondGameLeaderboard")
        newGCScore.value = score
        GKScore.reportScores([newGCScore], withCompletionHandler: {(error) -> Void in
            if error != nil {
                print("Score not submitted")
                // Continue
                self.gameOver = false
            } else {
                // Notify the delegate to show the game center leaderboard
                self.gameCenterDelegate!.gameOver()
            }
        })
    }

    // Handle collisions
    func didBeginContact(contact: SKPhysicsContact) {
        if !self.gamePaused {
            lifeLost()
        }
    }
    
    // Game Loop
    var _dLastShootTime: CFTimeInterval = 1
    override func update(currentTime: CFTimeInterval) {

        if !self.gamePaused && !self.gameOver {
            
            if currentTime - _dLastShootTime >= 1 {
                enemySprites.shoot(heroSprite)
                _dLastShootTime=currentTime
                
                // Increase score
                self.score++
                self.scoreNode.text = String(score)
            }
        }
    }
    
    // ---------------------------------
    // ---- Handle In-App Purchases ----
    // ---------------------------------
    
    private var request : SKProductsRequest!
    private var products : [SKProduct] = [] // List of available purchases
    private var greenShipPurchased = false // Used to enable/disable the 'green ship' feature
    
    // Open a menu with the available purchases
    func inAppPurchase() {
        
        let alert = UIAlertController(title: "In App Purchases", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        
        self.gamePaused = true
        
        // Add an alert action for each available product
        for (var i = 0; i < products.count; i++) {
            
            let currentProduct = products[i]
            if !(currentProduct.productIdentifier == "MySecondGameGreenShip" && greenShipPurchased) {
                
                // Get the localized price
                let numberFormatter = NSNumberFormatter()
                numberFormatter.numberStyle = .CurrencyStyle
                numberFormatter.locale = currentProduct.priceLocale
                
                // Add the alert action
                alert.addAction(UIAlertAction(title: currentProduct.localizedTitle + " " + numberFormatter.stringFromNumber(currentProduct.price)!, style: UIAlertActionStyle.Default)  { _ in
                    
                    // Perform the purchase
                    self.buyProduct(currentProduct)
                    self.gamePaused = false
                    })
            }
        }
        
        // Offer the restore option only if purchase info is not available
        if(greenShipPurchased == false) {
            alert.addAction(UIAlertAction(title: "Restore", style: UIAlertActionStyle.Default)  { _ in
                self.restorePurchasedProducts()
                self.gamePaused = false
                })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) { _ in
            self.gamePaused = false
            })
        
        // Show the alert
        self.view?.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Initialize the App Purchases
    func initInAppPurchases() {
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    
        // Get the list of possible purchases
        if self.request == nil {
            self.request = SKProductsRequest(productIdentifiers: Set(["MySecondGameGreenShip","MySecondGameDonate"]))
            self.request.delegate = self
            self.request.start()
        }
    }
    
    // Request a purchase
    func buyProduct(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    // Restore purchases
    func restorePurchasedProducts() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    // StoreKit protocoll method. Called when the AppStore responds
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        self.products = response.products 
        self.request = nil
    }
    
    // StoreKit protocoll method. Called when an error happens in the communication with the AppStore
    func request(request: SKRequest, didFailWithError error: NSError) {
        print(error)
        self.request = nil
    }
    
    // StoreKit protocoll method. Called after the purchase
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch (transaction.transactionState) {
                
            case .Purchased:
                if transaction.payment.productIdentifier == "MySecondGameGreenShip" {
                    handleGreenShipPurchased()
                }
                queue.finishTransaction(transaction)
                
            case .Restored:
                if transaction.payment.productIdentifier == "MySecondGameGreenShip" {
                    handleGreenShipPurchased()
                }
                queue.finishTransaction(transaction)
                
            case .Failed:
                print("Payment Error: %@", transaction.error)
                queue.finishTransaction(transaction)
            default:
                print("Transaction State: %@", transaction.transactionState)
            }
        }
    }
    
    // Called after the purchase to provide the 'green ship' feature
    func handleGreenShipPurchased() {
        greenShipPurchased = true
        checkAndActivateGreenShip()
        // persist the purchase locally
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "MySecondGameGreenShip")
    }
    
    // Called after applicattion start to check if the 'green ship' feature was purchased
    func checkAndActivateGreenShip() {
        if NSUserDefaults.standardUserDefaults().boolForKey("MySecondGameGreenShip") {
            greenShipPurchased = true
            heroSprite.color = UIColor.greenColor()
            heroSprite.colorBlendFactor=0.8
        }
    }
    
    


}
