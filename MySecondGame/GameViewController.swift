//
//  GameViewController.swift
//  MySecondGame
//
//  Created by STEFAN JOSTEN on 23.10.14.
//  Copyright (c) 2014 Stefan. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit

class GameViewController: UIViewController, GKGameCenterControllerDelegate, GameSceneDelegate {

    var scene : GameScene?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize game center
        self.initGameCenter()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Detect the screensize
        var sizeRect = UIScreen.mainScreen().applicationFrame
        var width = sizeRect.size.width * UIScreen.mainScreen().scale
        var height = sizeRect.size.height * UIScreen.mainScreen().scale
        
        // Create a fullscreen Scene object
        scene = GameScene(size: CGSizeMake(width, height))
        scene!.scaleMode = .AspectFill
        scene!.gameCenterDelegate = self
        
        // Configure the view.
        let skView = self.view as SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        skView.presentScene(scene)
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.LandscapeLeft.rawValue)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // Initialize Game Center
    func initGameCenter() {
        
        // Check if user is already authenticated in game center
        if GKLocalPlayer.localPlayer().authenticated == false {

            // Show the Login Prompt for Game Center
            GKLocalPlayer.localPlayer().authenticateHandler = {(viewController, error) -> Void in
                if viewController != nil {
                    self.scene!.gamePaused = true
                    self.presentViewController(viewController, animated: true, completion: nil)

                    // Add an observer which calls 'gameCenterStateChanged' to handle a changed game center state
                    let notificationCenter = NSNotificationCenter.defaultCenter()
                    notificationCenter.addObserver(self, selector:"gameCenterStateChanged", name: "GKPlayerAuthenticationDidChangeNotificationName", object: nil)
                }
            }
        }
    }
    
    // Continue the Game, if GameCenter Authentication state 
    // has been changed (login dialog is closed)
    func gameCenterStateChanged() {
        self.scene!.gamePaused = false
    }
    
    // Show game center leaderboard
    func gameOver() {
        
        var gcViewController = GKGameCenterViewController()
        gcViewController.gameCenterDelegate = self
        gcViewController.viewState = GKGameCenterViewControllerState.Leaderboards
        gcViewController.leaderboardIdentifier = "MySecondGameLeaderboard"
        
        // Show leaderboard
        self.presentViewController(gcViewController, animated: true, completion: nil)
    }
    
    // Continue the game after GameCenter is closed
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
        scene!.gameOver = false
    }
}
