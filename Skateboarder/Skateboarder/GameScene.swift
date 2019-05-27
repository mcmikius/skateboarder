//
//  GameScene.swift
//  Skateboarder
//
//  Created by Michail Bondarenko on 5/27/19.
//  Copyright © 2019 Michail Bondarenko. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint.zero
        let background = SKSpriteNode(imageNamed: "background")
        let xMid = frame.midX
        let yMid = frame.midY
        background.position = CGPoint(x: xMid, y: yMid)
        addChild(background)
        
    }
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
