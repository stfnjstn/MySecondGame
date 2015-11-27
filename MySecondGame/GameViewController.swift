//
//  GameViewController.swift
//  MySecondGame
//
//  Created by STEFAN on 23.10.14.
//  Copyright (c) 2014 Stefan. All rights reserved.
//

import UIKit
import SpriteKit
import GameKit
import iAd

class GameViewController: UIViewController, ADBannerViewDelegate, GKGameCenterControllerDelegate, GameSceneDelegate {

    var scene : GameScene?
    
    // Properties for Banner Ad
    var iAdBanner = ADBannerView()
    var bannerVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize game center
        self.initGameCenter()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Detect the screensize
        let sizeRect = UIScreen.mainScreen().applicationFrame
        let width = sizeRect.size.width * UIScreen.mainScreen().scale
        let height = sizeRect.size.height * UIScreen.mainScreen().scale
        
        // Create a fullscreen Scene object
        scene = GameScene(size: CGSizeMake(width, height))
        scene!.scaleMode = .AspectFill
        scene!.gameCenterDelegate = self
        
        // Configure the view.
        let skView = self.view as! SKView
        //skView.showsFPS = true
        //skView.showsNodeCount = true
        
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true
        
        skView.presentScene(scene)
        
        // Prepare banner Ad
        iAdBanner.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.width, 50)
        iAdBanner.delegate = self
        bannerVisible = false
        
        // Prepare fullscreen Ad
        UIViewController.prepareInterstitialAds()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.LandscapeLeft
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
                    //self.scene!.gamePaused = true
                    self.presentViewController(viewController!, animated: true, completion: nil)

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
        
        let gcViewController = GKGameCenterViewController()
        gcViewController.gameCenterDelegate = self
        gcViewController.viewState = GKGameCenterViewControllerState.Leaderboards
        gcViewController.leaderboardIdentifier = "MySecondGameLeaderboard"
        
        // Show leaderboard
        if GKLocalPlayer.localPlayer().authenticated == true {
            self.presentViewController(gcViewController, animated: true, completion: {
        })
        } else {
            // Show fullscreen Ad
            self.openAds(self)
        }
    }
    
    // Continue the game after GameCenter is closed
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
        //scene!.gameOver = false
        
        // Show fullscreen Ad
        openAds(self)
    }
    
    // Show banner, if Ad is successfully loaded.
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        if(bannerVisible == false) {
            
            // Add banner Ad to the view
            if(iAdBanner.superview == nil) {
                self.view.addSubview(iAdBanner)
            }
            
            // Move banner into visible screen frame:
            UIView.beginAnimations("iAdBannerShow", context: nil)
            banner.frame = CGRectOffset(banner.frame, 0, -banner.frame.size.height)
            UIView.commitAnimations()
            
            bannerVisible = true
        }
    }
    
    // Hide banner, if Ad is not loaded.
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        if(bannerVisible == true) {
            // Move banner below screen frame:
            UIView.beginAnimations("iAdBannerHide", context: nil)
            banner.frame = CGRectOffset(banner.frame, 0, banner.frame.size.height)
            UIView.commitAnimations()
            bannerVisible = false
        }
    }
    
    // Open a fullscreen Ad
    func openAds(sender: AnyObject) {
        // Create an alert
        let alert = UIAlertController(title: "", message: "Play again?", preferredStyle: UIAlertControllerStyle.Alert)
        
        // Play again option
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default)  { _ in
            self.scene!.gameOver = false
            })
        
        // Show fullscreen Ad option
        alert.addAction(UIAlertAction(title: "Watch Ad", style: UIAlertActionStyle.Default)  { _ in
            self.interstitialPresentationPolicy = ADInterstitialPresentationPolicy.Manual
            self.requestInterstitialAdPresentation()
            self.scene!.gameOver = false
            })
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
