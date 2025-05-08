//
//  CutScene1.swift
//  PacMan
//
//  Kush Desai and James Park
//

import SpriteKit

class CutScene1: SKScene {
    
    override func didMove(to view: SKView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 14) {
            if let newScene = SKScene(fileNamed: "GameScene") {
                newScene.scaleMode = self.scaleMode
                self.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1))
            }
        }
    }
}
