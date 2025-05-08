//
//  OpeningScene2.swift
//  PacMan
//
//  Kush Desai and James Park
//

import SpriteKit

class OpeningScene2: SKScene {
    
    // MARK: - METHODS
    override func didMove(to view: SKView) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.changeScene(scene: "OpeningScene1")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        guard let tapped = tappedNodes.first else {return}
        
        if tapped.name == "lblStart" {
            UserDefaults.standard.set(5, forKey: "lives")
            UserDefaults.standard.set(1, forKey: "level")
            UserDefaults.standard.set(0, forKey: "score")
            changeScene(scene: "GameScene")
        }
    }
    
    // MARK: - NODE METHODS
    func changeScene(scene: String) {
        if let newScene = SKScene(fileNamed: scene){
            newScene.scaleMode = self.scaleMode
            view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1))
        }
    }
}
