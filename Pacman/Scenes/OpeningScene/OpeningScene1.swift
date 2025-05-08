//
//  OpeningScene1.swift
//  PacMan
//
//  Kush Desai and James Park
//

import SpriteKit

class OpeningScene1: SKScene {
    
    // MARK: - PROPERTIES
    var timeLastUpdated: CFTimeInterval = 0
    
    //Mark: - METHODS
    override func update(_ currentTime: TimeInterval){
        if timeLastUpdated == 0 {
            timeLastUpdated = currentTime
            return
        } else if currentTime - timeLastUpdated > 22.0 {
            changeScene(scene: "OpeningScene2")
        } else {
            return
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
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
    func changeScene(scene: String){
        if let newScene = SKScene(fileNamed: scene){
            newScene.scaleMode = self.scaleMode
            view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1))
        }
    }
}
