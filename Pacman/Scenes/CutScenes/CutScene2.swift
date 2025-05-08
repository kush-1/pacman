//
//  CutScene2.swift
//  PacMan
//
//  Kush Desai and James Park
//

import SpriteKit

class CutScene2: SKScene {
    
    override func didMove(to view: SKView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            if let newScene = SKScene(fileNamed: "GameScene") {
                newScene.scaleMode = self.scaleMode
                self.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1))
            }
        }
    }
}
