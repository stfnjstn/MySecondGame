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



class GameViewController: UIViewController {

    var scene : GameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initGameCenter()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Detect the screensize
        var sizeRect = UIScreen.mainScreen().applicationFrame
        var width = sizeRect.size.width * UIScreen.mainScreen().scale
        var height = sizeRect.size.height * UIScreen.mainScreen().scale
        
        // Scene should be shown in fullscreen mode
        scene = GameScene(size: CGSizeMake(width, height))
        
        
        // Configure the view.
        let skView = self.view as SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        /* Set the scale mode to scale to fit the window */
        scene!.scaleMode = .AspectFill
        
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
    
    
    var gameCenterAvailable = false
    func initGameCenter() {
        if GKLocalPlayer.localPlayer().authenticated == false {
            gameCenterAvailable = false
            // Start the Login Promt for Game Center
            GKLocalPlayer.localPlayer().authenticateHandler = {(viewController, error) -> Void in
                if viewController != nil {
                    self.scene!.gamePaused = true
                    self.presentViewController(viewController, animated: true, completion: nil)
                    // Add an observer to check status again after LoginState has been changed
                    let notificationCenter = NSNotificationCenter.defaultCenter()
                    notificationCenter.addObserver(self, selector:"gameCenterStateChanged", name: "GKPlayerAuthenticationDidChangeNotificationName", object: nil)
                }else{
                    println((GKLocalPlayer.localPlayer().authenticated))
                    self.scene!.gamePaused = false
                }
            }
            
        } else {
            gameCenterAvailable = true
        }
    }
    
    func gameCenterStateChanged() {
        initGameCenter()
    }
}
