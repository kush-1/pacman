//
//  GameScene.swift
//  PacMan
//
//  Kush Desai and James Park
//

import SpriteKit

class GameScene: SKScene {

    // MARK: - PROPERTIES
    var lblScore: SKLabelNode?
    var lblHiScore: SKLabelNode?
    
    let bonusBase: Int = 10000
    var bonusMultiplier: Int = 1
    
    let pacman: Player = Player()
    let blinky: Ghost = Ghost()
    let pinky: Ghost = Ghost()
    let inky: Ghost = Ghost()
    let clyde: Ghost = Ghost()
    
    var score: Int = 0{
        didSet {
            lblScore?.text = String(format: "%0d", score)
            if score > hiscore {hiscore = score}
            if score > bonusBase * bonusMultiplier {
                lblScore?.run(SKAction.playSoundFileNamed("pacman_extrapac.wav", waitForCompletion: true))
                bonusMultiplier += 1
                lives += 1
            }
        }
    }
    
    var hiscore: Int = 0 {
        didSet {
            lblHiScore?.text = String(format: "%0d", hiscore)
            UserDefaults.standard.set(hiscore, forKey: "hiscore")
        }
    }
    
    var lives: Int = 0 {
        willSet {
            self.globalDotCounter = 0
        }
        didSet {
            if lives < 0 {
                printContent("Game Over")
                changeScene()
            }
            for node in children {
                if node.name == "paclife" { node.removeFromParent()}
            }
            if lives > 1 {
                for life in 1...lives-1 {
                    let pacmanLife: SKSpriteNode = SKSpriteNode(imageNamed: "Pacman-Opened")
                    pacmanLife.name = "paclife"
                    pacmanLife.size = CGSize(width: 86, height: 86)
                    pacmanLife.position = CGPoint(x: 144 + CGFloat(life) * pacmanLife.size.width, y: 96)
                    addChild(pacmanLife)
                }
            }
        }
    }
    
    var level: Int = 0 {
        didSet {
            levelData.setupLevel(level: level)
        }
    }
    
    var timeOfGhostRelease: CFTimeInterval = 0
    var globalDotCounterActive: Bool = false
    var globalDotCounter: Int = 0
    var dotsEaten: Int = 0
    
    var isTargetOn: Bool = false
    
    var timeOfStateChance: CFTimeInterval = 0
    var stateArrayPointer: Int = 0
    
    var timeOfFrighten: CFTimeInterval = 0
    var frightenedGhostScore: Int = 100
    
    var timeOfBonus: CFTimeInterval = 0
    
    var isBonusActive: Bool = false
    var isBonusShowing: Bool = false
    var theBonus: SKSpriteNode?
    
    var deathDelay: CFTimeInterval = 0
    
    // MARK: - METHODS
    override func didMove(to view: SKView) {
        // Make sure a map exists - if so create game
        for node in self.children {
            if node is SKTileMapNode {
                if let map: SKTileMapNode = node as? SKTileMapNode {
                    lives = UserDefaults.standard.integer(forKey: "lives")
                    level = UserDefaults.standard.integer(forKey: "level")
                    score = UserDefaults.standard.integer(forKey: "score")
                    hiscore = UserDefaults.standard.integer(forKey: "hiscore")
                    if level == 1 {scene?.run(gameStartSound)}
                    setupGameBoard(map: map)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                        playerLabel.removeFromParent()
                        readyLabel.removeFromParent()
                        self.addChild(self.pacman)
                        self.addChild(self.blinky)
                        self.addChild(self.pinky)
                        self.addChild(self.inky)
                        self.addChild(self.clyde)
                        globalHoldState = globalState
                    }
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if timeOfGhostRelease.isZero {timeOfGhostRelease = currentTime}
        if timeOfStateChance.isZero {timeOfStateChance = currentTime}
        
        //check to see if ghosts need to be released
        if self.globalDotCounterActive {
            //after a life is lost the ghost will release based on the global dot counter
            if globalDotCounter >= 7 && pinky.isActive == false{
                pinky.release()
            }
            if globalDotCounter >= 17 && inky.isActive == false{
                inky.release()
            }
            if globalDotCounter >= 32 && clyde.isActive == false{
                clyde.release()
            }
        } else {
            // before a life is lost the ghost release based on time or the number of dots eaten
            let secondsToRelease: CGFloat = level < 5 ? 4 : 3
            if currentTime - timeOfGhostRelease > secondsToRelease {
                var ghostToRelease: Ghost = blinky
                ghostToRelease = readyPreferredGhost()
                if ghostToRelease == blinky && blinky.isActive {
                    // do nothing
                } else {
                    ghostToRelease.release()
                    timeOfGhostRelease = currentTime
                }
            } else {
                for node in self.children {
                    if let theGhost: Ghost = node as? Ghost {
                        if theGhost.state == .waiting && dotsEaten >= theGhost.dotsRequiredForEscape {
                            dotsEaten = 0
                            theGhost.release()
                        }
                    }
                }
            }
        }
        
        // handle state changes from scatter to chase
        if currentTime - timeOfStateChance > levelData.stateTime[stateArrayPointer] {
            timeOfStateChance = currentTime
            stateArrayPointer += 1
            if globalHoldState == .chase {
                globalHoldState = .scatter
            } else if globalHoldState == .scatter {
                globalHoldState = .chase
            }
            
            for node in self.children {
                if let theGhost: Ghost = node as? Ghost {
                    if theGhost.isActive && theGhost.state != .eaten && theGhost.state != .frightened {
                        theGhost.mustReverse = true
                        theGhost.state = globalHoldState
                    }
                }
            }
        }
        
        // handle the state change from frighten to what it was prior
        if timeOfFrighten != 0 && currentTime - timeOfFrighten > levelData.frightTime {
            globalState = globalHoldState
            timeOfFrighten = 0
            for node in self.children {
                if let theGhost: Ghost = node as? Ghost {
                    if theGhost.state == .frightened {
                        theGhost.state = globalHoldState
                    }
                }
            }
        }
        
        // show the bonus item
        if isBonusActive {
            if currentTime - timeOfBonus > 9 {
                isBonusActive = false
                isBonusShowing = false
                theBonus?.removeFromParent()
            } else {
                if isBonusShowing == false {
                    isBonusShowing = true
                    showBonus()
                }
            }
        }
        
        // move the ghosts
        for node in self.children {
            if let theGhost: Ghost = node as? Ghost {
                if theGhost.isActive {
                    theGhost.move(pacman: pacman, blinky: blinky)
                    theGhost.showTarget(on: isTargetOn)
                }
            }
        }
        
        // move pacman
        if pacman.isMoving == false && pacman.isPlayerAlive {pacman.move()}
        
        // remove any ghosts if pacman is not alive
        if pacman.isPlayerAlive == false && blinky.hadReset == false {
            blinky.hadReset = true
            blinky.removeFromParent()
            pinky.removeFromParent()
            inky.removeFromParent()
            clyde.removeFromParent()
            blinky.setGhostDefaults(name: "Blinky", state: .scatter, level: level)
            inky.setGhostDefaults(name: "Inky", state: .waiting, level: level)
            pinky.setGhostDefaults(name: "Pinky", state: .waiting, level: level)
            clyde.setGhostDefaults(name: "Clyde", state: .waiting, level: level)
            
            blinky.run(SKAction.move(to: startPositions["Blinky"]!, duration: 0))
            inky.run(SKAction.move(to: startPositions["Inky"]!, duration: 0))
            pinky.run(SKAction.move(to: startPositions["Pinky"]!, duration: 0))
            clyde.run(SKAction.move(to: startPositions["Clyde"]!, duration: 0))
            
        }
        
        if currentTime - deathDelay > 5 && deathDelay != .zero {
            deathDelay = .zero
            pacman.create()
            pacman.isMoving = false
            addChild(pacman)
            addChild(blinky)
            addChild(inky)
            addChild(pinky)
            addChild(clyde)
            blinky.hadReset = false 
        }
        
        //remove the dots and bonus items as eaten and save score
        for node in children {
            if node.name == "Small-Dot" && pacman.position == node.position {
                score += 10
                node.removeFromParent()
                totalDotsRemaining -= 1
                if totalDotsRemaining == 0{
                    changeScene()
                } else if totalDotsRemaining == levelData.elroy1Trigger {
                    blinky.isElroy1 = true
                    blinky.isElroy2 = false
                    blinky.state = .chase
                } else if totalDotsRemaining == levelData.elroy2Trigger {
                    blinky.isElroy1 = false
                    blinky.isElroy2 = true
                    blinky.state = .chase
                } else if totalDotsRemaining == 74 || totalDotsRemaining == 174 {
                    isBonusActive = true
                    timeOfBonus = currentTime
                }
                
                timeOfGhostRelease = currentTime
                if globalDotCounterActive == false {dotsEaten += 1}
                if globalDotCounterActive {globalDotCounter += 1}
            } else if node.name == "Large-Dot" && pacman.position == node.position {
                score += 50
                frightenedGhostScore = 100
                node.removeFromParent()
                totalDotsRemaining -= 1
                if totalDotsRemaining == 0 {
                    changeScene()
                } else if totalDotsRemaining == levelData.elroy1Trigger {
                    blinky.isElroy1 = true
                    blinky.isElroy2 = false
                    blinky.state = .chase
                } else if totalDotsRemaining == levelData.elroy2Trigger {
                    blinky.isElroy1 = false
                    blinky.isElroy2 = true
                    blinky.state = .chase
                } else if totalDotsRemaining == 74 || totalDotsRemaining == 174 {
                    isBonusActive = true
                    timeOfBonus = currentTime
                }
                
                timeOfGhostRelease = currentTime
                if globalDotCounterActive == false {dotsEaten += 1}
                if globalDotCounterActive {globalDotCounter += 1}
                globalState = .frightened
                timeOfFrighten = currentTime
                for node in self.children {
                    if let theGhost: Ghost = node as? Ghost {
                        if theGhost.isActive {
                            theGhost.mustReverse = true
                            theGhost.state = .frightened
                        }
                    }
                }
            } else if node.name == "bonus" && pacman.position == node.position {
                node.removeFromParent()
                pacman.run(bonusEatenSound)
                score += levelData.bonusPoints
                bonusLabel.text = String(format: "%4d", levelData.bonusPoints)
                bonusLabel.fontColor = .yellow
                bonusLabel.fontSize = 36
                bonusLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 - 200)
                bonusLabel.zPosition = 100
                addChild(bonusLabel)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                    bonusLabel.removeFromParent()
                }
            }
            
            // remove the ghost if they are frightened and pacman eats them
            if node.isKind(of: Ghost.self) && pacman.intersects(node) && pacman.isPlayerAlive {
                if node.contains(CGPoint(x: pacman.position.x - 10, y: pacman.position.y)) ||
                    node.contains(CGPoint(x: pacman.position.x + 10, y: pacman.position.y)) ||
                    node.contains(CGPoint(x: pacman.position.x, y: pacman.position.y - 10)) ||
                    node.contains(CGPoint(x: pacman.position.x, y: pacman.position.y + 10)) {
                    if let theGhost: Ghost = node as? Ghost {
                        if theGhost.state == .frightened {
                            print("Pacman ate \(theGhost.name!)")
                            theGhost.state = .eaten
                            pacman.run(ghostEatenSound)
                            score += frightenedGhostScore * 2
                            frightenedGhostScore = frightenedGhostScore * 2
                        } else if theGhost.state == .eaten {
                            // do nothing
                        } else {
                            print("Pacman touches \(theGhost.name!)")
                            pacman.isPlayerAlive = false
                            pacman.removeAllActions()
                            pacman.run(deathSequence)
                            lives -= 1
                            deathDelay = currentTime
                        }
                    }
                }
                    
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        guard let tapped = tappedNodes.first else {return}
        
        switch tapped.name {
        case "btnUp":
            pacman.proposedDirection = .up
        case "btnDown":
            pacman.proposedDirection = .down
        case "btnLeft":
            pacman.proposedDirection = .left
        case "btnRight":
            pacman.proposedDirection = .right
        case "target":
            isTargetOn.toggle()
        default:
            break
        }
    }
    
    // MARK: - NODE METHODS
    private func setupGameBoard(map: SKTileMapNode) {
        var thisPoint: CGPoint = CGPoint()
        for row in 0..<map.numberOfRows {
            for col in 0..<map.numberOfColumns {
                thisPoint = grindToCoord(column: col, row: row)
                if col < 2 || col > 29 || row < 4 || row > 34 {
                    // these are the files outside the playable board
                    wallSpace.append(thisPoint)
                } else if let tile = map.tileDefinition(atColumn: col, row: row) {
                    // these are the walls or blank spaes inside the playable area
                    if tile.name == "Blank" {
                        availableSpace.append(thisPoint)
                    } else {
                        wallSpace.append(thisPoint)
                    }
                } else {
                    //these are the points wherew we will place the dots
                    availableSpace.append(thisPoint)
                    let dot: SKSpriteNode = SKSpriteNode(imageNamed: "Large-Dot")
                    if (col == 3 && row == 11) || (col == 3 && row == 31) || (col == 28 && row == 11) || (col == 28 && row == 31){
                        dot.name = "Large-Dot"
                        dot.size = CGSize(width: map.tileSize.width, height: map.tileSize.height)
                    } else {
                        dot.name = "Small-Dot"
                        dot.size = CGSize(width: map.tileSize.width / 4, height: map.tileSize.height / 4)
                    }
                    
                    dot.position = CGPoint(x: thisPoint.x, y: thisPoint.y)
                    addChild(dot)
                    totalDotsRemaining += 1
                }
            }
        }
        
        // player and ready label
        playerLabel.text = "PLAYER ONE"
        playerLabel.color = .yellow
        playerLabel.fontSize = 64
        playerLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 + 80)
        playerLabel.zPosition = 100
        addChild(playerLabel)
        
        readyLabel.text = "READY!"
        readyLabel.fontColor = .cyan
        readyLabel.fontSize = 64
        readyLabel.position = CGPoint(x: frame.width / 2, y: frame.height / 2 - 200)
        addChild(readyLabel)
        
        // bonus items
        var bonusArrayStart: Int = 0
        var bonusArrayStop: Int = 0
        var bonusOffset: Int = 0
        
        if level > 18 {
            bonusArrayStart = 13
            bonusArrayStop = 20
        } else {
            bonusArrayStart = max((level % 21) - 7, 0)
            bonusArrayStop = level
        }
        
        for bonus in bonusArrayStart..<bonusArrayStop {
            let bonusSprite: SKSpriteNode = SKSpriteNode(imageNamed: "\(levelData.bonusArray[bonus])")
            bonusSprite.size = CGSize(width: 110, height: 110)
            bonusSprite.position = CGPoint(x: frame.width - 144 - (CGFloat(bonusOffset) * bonusSprite.size.width), y: 96)
            addChild(bonusSprite)
            bonusOffset += 1
        }
        
        // score and high score labels
        lblScore = self.childNode(withName: "lblScore") as? SKLabelNode
        lblHiScore = self.childNode(withName: "lblHiScore") as? SKLabelNode
        
        // setup players
        pacman.create()
        blinky.setGhostDefaults(name: "Blinky", state: .scatter, level: level)
        pinky.setGhostDefaults(name: "Pinky", state: .waiting, level: level)
        inky.setGhostDefaults(name: "Inky", state: .waiting, level: level)
        clyde.setGhostDefaults(name: "Clyde", state: .waiting, level: level)
    }
    
    func readyPreferredGhost() -> Ghost {
        let preferredGhost: [Ghost] = [blinky, pinky, inky, clyde]
        for ghost in preferredGhost {
            if ghost.isActive == false && ghost.state == .waiting {
                return ghost
            }
        }
        return blinky
    }
    
    private func showBonus() {
        theBonus = SKSpriteNode(imageNamed: levelData.bonusArray[level - 1])
        theBonus?.name = "bonus"
        theBonus?.size = CGSize(width: 86, height: 86)
        theBonus?.position = grindToCoord(column: 16, row: 17)
        theBonus?.zPosition = 100
        addChild(theBonus!)
    }
    
    private func changeScene() {
        var scene: String
        
        for child in self.children {child.isPaused = true}
        
        if lives < 0 {
            scene = "OpeningScene1"
            let gameOver: SKSpriteNode = SKSpriteNode(imageNamed: "GameOver")
            gameOver.position = CGPoint(x: 512, y: 512)
            addChild(gameOver)
        } else if level == 2 {
            scene = "CutScene1"
        } else if level == 5 {
            scene = "CutScene2"
        } else {
            scene = "GameScene"
        }
        
        level += 1
        UserDefaults.standard.set(score, forKey: "score")
        UserDefaults.standard.set(lives, forKey: "lives")
        UserDefaults.standard.set(level, forKey: "level")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.removeAllChildren()
            if let newScene = SKScene(fileNamed: scene){
                newScene.scaleMode = self.scaleMode
                self.view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 1))
            }
        }
    }
}
