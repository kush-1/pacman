//
//  Ghost.swift
//  PacMan
//
//  Kush Desai and James Park
//

import SpriteKit

class Ghost: SKSpriteNode {
    
    // MARK: - PROPERTIES
    var state: State = .scatter
    var direction: Direction = .left
    var moveSpeed: CGFloat = levelData.ghostNormalSpeed
    var isActive: Bool = false
    var isAlignedToGrid: Bool = false
    var isMoving: Bool = false
    var isElroy1: Bool = false
    var isElroy2: Bool = false
    
    private var chaseTarget: CGPoint = .zero
    private var scatterTarget: CGPoint = grindToCoord(column: 28, row: 35)
    let distanceFromPoint: Double = 48
    
    var dotsRequiredForEscape: Int = 0
    
    var mustReverse: Bool = false
    
    var hadReset: Bool = false
    
    // MARK: - PUBLIC METHODS
    func setGhostDefaults(name: String, state: State, level: Int) {
        self.texture = SKTexture(imageNamed: "\(name)-A-Down")
        self.name = name
        self.position = startPositions[name] ?? .zero
        self.zPosition = 1
        self.size = CGSize(width: 86, height: 86)
        self.state = state
        self.direction = .left
        self.moveSpeed = levelData.ghostNormalSpeed
        self.isActive = name == "Blinky" ? true : false
        self.isAlignedToGrid = false
        self.isMoving = false
        self.isElroy1 = false
        self.isElroy2 = false
        self.scatterTarget = scatterTargets[name] ?? .zero
        self.chaseTarget = .zero
        
        if level == 1 {
            self.dotsRequiredForEscape = self.name == "Blinky" ? 0 : self.name == "Pinky" ? 0 : self.name == "Inky" ? 30 : 60
        } else if level == 2 {
            self.dotsRequiredForEscape = self.name == "Blinky" ? 0 : self.name == "Pinky" ? 0 : self.name == "Inky" ? 0 : 50
        } else {
            self.dotsRequiredForEscape = 0
        }
    }
    
    func showTarget(on: Bool) {
        guard self.chaseTarget != .zero else { return }
        if scene?.childNode(withName: "\(self.name ?? "Someone")'s-Target") != nil {
            scene?.childNode(withName: "\(self.name ?? "Someone")'s-Target")?.removeFromParent()
        }
        if scene?.childNode(withName: "\(self.name ?? "Someone")'s-TargetLine") != nil {
            scene?.childNode(withName: "\(self.name ?? "Someone")'s-TargetLine")?.removeFromParent()
        }
        
        if on {
            let target: SKSpriteNode = SKSpriteNode(imageNamed: "\(self.name ?? "Someone")'s-Target")
            target.name = "\(self.name ?? "Someone")'s-Target"
            target.zPosition = 5
            target.size = CGSize(width: 48, height: 48)
            target.position = self.chaseTarget
            scene?.addChild(target)
            let targetLine: SKShapeNode = SKShapeNode(start: self.position, end: self.chaseTarget, strokeColor: .cyan, lineWidth: 2)
            targetLine.name = "\(self.name ?? "Someone")'s-TargetLine"
            targetLine.zPosition = 5
            scene?.addChild(targetLine)
        }
    }
    
    func release() {
        guard self.state == .waiting else {return}
        self.state = .escaping
        
        let alignCenter: SKAction = SKAction.move(to: CGPoint(x: 768, y: 984), duration: CFTimeInterval(distanceFromPoint / self.moveSpeed))
        let moveUp: SKAction = SKAction.move(to: CGPoint(x: 768, y: 1128), duration: CFTimeInterval(distanceFromPoint / self.moveSpeed))
        let pause: SKAction = SKAction.wait(forDuration: 0.2)
        let release: SKAction = SKAction.run {
            self.state = globalState
            self.isAlignedToGrid = false
            self.isActive = true
            self.isMoving = false
            self.direction = .left
        }
        let escapeSeq: SKAction = SKAction.sequence([alignCenter, pause, moveUp, release])
        self.run(escapeSeq)
    }
    
    func reverse() {
        if self.direction == .up {self.direction = .down}
        if self.direction == .down {self.direction = .up}
        if self.direction == .left {self.direction = .right}
        if self.direction == .right {self.direction = .left}
        self.mustReverse = false
    }
    
    func move(pacman: Player, blinky: Ghost) {
        guard self.isMoving == false else {return}
        
        var proposedLocation: CGPoint = .zero
        
        self.isMoving = true
        if mustReverse {self.reverse()}
        
        if self.isAlignedToGrid == false {
            self.isAlignedToGrid = true
            self.position = CGPoint(x: self.position.x - 24, y: self.position.y)
            self.isMoving = false
            return
        }
        
        if self.position == CGPoint(x: 1416, y: 984) && self.direction == .right {
            self.position = CGPoint(x: 120, y: 984)
            self.isMoving = false
            return
        } else if self.position == CGPoint(x: 120, y: 984) && self.direction == .left {
            self.position = CGPoint(x: 1416, y: 984)
            self.isMoving = false
            return
        }
        
        proposedLocation = self.state == .frightened ? self.findRandomMove(heading: self.direction) : self.chooseTarget(pacman: pacman, blinky: blinky)
        
        // if the ghost is eaten and at the entrance of the ghost house
        let moveLeft: SKAction = SKAction.move(to: proposedLocation, duration: CFTimeInterval(distanceFromPoint / self.moveSpeed))
        let moveUp: SKAction = SKAction.move(to: CGPoint(x: 768, y: 1128), duration: CFTimeInterval(distanceFromPoint / self.moveSpeed))
        let pause: SKAction = SKAction.wait(forDuration: 0.2)
        let alignLeft: SKAction = SKAction.move(to: CGPoint(x: 672, y: 984), duration: CFTimeInterval(distanceFromPoint / self.moveSpeed))
        let alignCenter: SKAction = SKAction.move(to: CGPoint(x: 768, y: 984), duration: CFTimeInterval(distanceFromPoint/self.moveSpeed))
        let alignRight: SKAction = SKAction.move(to: CGPoint(x: 864, y: 984), duration: CFTimeInterval(distanceFromPoint / self.moveSpeed))
        let reset: SKAction = SKAction.run {
            self.state = .waiting
            self.isAlignedToGrid = false
            self.isActive = false
            self.isMoving = false
            self.adjustTexture()
        }
        let release: SKAction = SKAction.run {
            self.state = globalHoldState
            self.isAlignedToGrid = false
            self.isActive = true
            self.isMoving = false
            self.direction = .left
        }
        if self.name == "Blinky" {
            if proposedLocation == CGPoint(x: 768, y: 1128) && self.state == .eaten {
                let blinkySeq: SKAction = SKAction.sequence([moveLeft, pause, alignCenter, pause, moveUp, release])
                self.run(blinkySeq)
                return
            }
        } else if self.name == "Inky" {
            if proposedLocation == CGPoint(x: 768, y: 1128) && self.state == .eaten {
                let inkySeq: SKAction = SKAction.sequence([moveLeft, pause, alignCenter, pause, alignLeft, pause, reset])
                self.run(inkySeq)
                return
            }
        } else if self.name == "Pinky" {
            if proposedLocation == CGPoint(x: 768, y: 1128) && self.state == .eaten {
                let pinkySeq: SKAction = SKAction.sequence([moveLeft, pause, alignCenter, pause, reset])
                self.run(pinkySeq)
                return
            }
        } else if self.name == "Clyde" {
            if proposedLocation == CGPoint(x: 768, y: 1128) && self.state == .eaten {
                let clydeSeq: SKAction = SKAction.sequence([moveLeft, pause, alignCenter, pause, alignRight, pause, reset])
                self.run(clydeSeq)
                return
            }
        }
                                                 
        guard availableSpace.contains(proposedLocation) else {
            printContent("move not allowed")
            self.isMoving = false
            return
        }
        
        self.moveSpeed = adjustSpeed(proposedLocation: proposedLocation)
        
        self.adjustTexture()
        
        let move: SKAction = SKAction.move(to: proposedLocation, duration: CFTimeInterval(distanceFromPoint / self.moveSpeed))
        let stop: SKAction = SKAction.run {
            self.isMoving = false
        }
        let sequence: SKAction = SKAction.sequence([move, stop])
        self.run(sequence)
        
    }
    
    private func chooseTarget(pacman: Player, blinky: Ghost) -> CGPoint {
        switch self.state {
        case .waiting, .ready, .escaping:
            return .zero
        case .scatter:
            self.chaseTarget = self.scatterTarget
        case .chase:
            switch self.name {
            case "Blinky":
                self.chaseTarget = pacman.position
            case "Pinky":
                if pacman.direction == .left {
                    self.chaseTarget = CGPoint(x: pacman.position.x - 192, y: pacman.position.y)
                } else if pacman.direction == .right {
                    self.chaseTarget = CGPoint(x: pacman.position.x + 192, y: pacman.position.y)
                } else if pacman.direction == .down {
                    self.chaseTarget = CGPoint(x: pacman.position.x, y: pacman.position.y - 192)
                } else {
                    self.chaseTarget = CGPoint(x: pacman.position.x - 192, y: pacman.position.y + 192)
                }
            case "Inky":
                var pointA: CGPoint = .zero
                let pointB: CGPoint = blinky.position
                var vector: CGVector
                if pacman.direction == .left {
                    pointA = CGPoint(x: pacman.position.x - 96, y: pacman.position.y)
                } else if pacman.direction == .right {
                    pointA = CGPoint(x: pacman.position.x + 96, y: pacman.position.y)
                } else if pacman.direction == .down {
                    pointA = CGPoint(x: pacman.position.x, y: pacman.position.y - 96)
                } else {
                    pointA = CGPoint(x: pacman.position.x - 96, y: pacman.position.y + 96)
                }
                vector = CGVector(dx: pointA.x - pointB.x, dy: pointA.y - pointB.y)
                self.chaseTarget = CGPoint(x: pointA.x + vector.dx, y: pointA.y + vector.dy)
            case "Clyde":
                if pacman.position.x - abs(self.position.x) < 384 || pacman.position.y - abs(self.position.y) < 384 {
                    self.chaseTarget = self.scatterTarget
                } else {
                    self.chaseTarget = pacman.position
                }
            default:
                return .zero
            }
        case .frightened:
            return self.findRandomMove(heading: self.direction)
        case .eaten:
            self.chaseTarget = CGPoint(x: 792, y: 1128)
        }
        return findBestMove(from: self.position, to: self.chaseTarget, heading: self.direction)
    }
    
    private func findBestMove(from: CGPoint, to: CGPoint, heading: Direction) -> CGPoint {
        
        // see if the ghost is ready to enter the ghost house
        if self.state == .eaten && self.position == self.chaseTarget {
            return CGPoint(x: 768, y: 1128)
        }
        
        var possiblePoints: [CGPoint] = [
            CGPoint(x: self.position.x - 48, y: self.position.y), //left
            CGPoint(x: self.position.x + 48, y: self.position.y), //right
            CGPoint(x: self.position.x, y: self.position.y + 48), //up
            CGPoint(x: self.position.x, y: self.position.y - 48) //down
        ]
        
        var bestMove: CGPoint = .zero
        var distance: CGFloat = 10000000
        
        if heading == .up {
            possiblePoints.remove(at: possiblePoints.firstIndex(of: CGPoint(x: self.position.x, y: self.position.y - 48))!)
        } else if heading == .down {
            possiblePoints.remove(at: possiblePoints.firstIndex(of: CGPoint(x: self.position.x, y: self.position.y + 48))!)
        } else if heading == .left {
            possiblePoints.remove(at: possiblePoints.firstIndex(of: CGPoint(x: self.position.x + 48, y: self.position.y))!)
        } else if heading == .right {
            possiblePoints.remove(at: possiblePoints.firstIndex(of: CGPoint(x: self.position.x - 48, y: self.position.y))!)
        }
        
        for point in possiblePoints {
            if availableSpace.contains(point) == false {
                possiblePoints.remove(at: possiblePoints.firstIndex(of: point)!)
            }
        }
        
        if possiblePoints.count == 0 {
            print("There was a problem finding a point to move to")
            return self.position
        } else if possiblePoints.count == 1 {
            if possiblePoints[0].x > self.position.x {
                self.direction = .right
            } else if possiblePoints[0].x < self.position.x {
                self.direction = .left
            } else if possiblePoints[0].y > self.position.y {
                self.direction = .up
            } else {
                self.direction = .down
            }
            return possiblePoints[0]
        } else {
            for index in 0..<possiblePoints.count {
                if (possiblePoints[index].x - to.x) * (possiblePoints[index].x - to.x) + (possiblePoints[index].y - to.y) * (possiblePoints[index].y - to.y) < distance {
                    distance = (possiblePoints[index].x - to.x) * (possiblePoints[index].x - to.x) + (possiblePoints[index].y - to.y) * (possiblePoints[index].y - to.y)
                    bestMove = possiblePoints[index]
                }
            }
        }
        
        if bestMove.x > self.position.x {
            self.direction = .right
        } else if bestMove.x < self.position.x {
            self.direction = .left
        } else if bestMove.y > self.position.y {
            self.direction = .up
        } else {
            self.direction = .down
        }
        
        return bestMove
    }
    
    private func findRandomMove(heading: Direction) -> CGPoint {
        var possibleDirection: [Direction] = [.left, .right, .up, .down]
        var possiblePoint: CGPoint = .zero
        
        if heading == .up {
            possibleDirection.remove(at: possibleDirection.firstIndex(of: .down)!)
        } else if heading == .down {
            possibleDirection.remove(at: possibleDirection.firstIndex(of: .up)!)
        } else if heading == .left {
            possibleDirection.remove(at: possibleDirection.firstIndex(of: .right)!)
        } else if heading == .right {
            possibleDirection.remove(at: possibleDirection.firstIndex(of: .left)!)
        }
        
        for direction in possibleDirection {
            switch direction {
            case .left:
                possiblePoint = CGPoint(x: self.position.x - 48, y: self.position.y)
            case .right:
                possiblePoint = CGPoint(x: self.position.x + 48, y: self.position.y)
            case .up:
                possiblePoint = CGPoint(x: self.position.x, y: self.position.y + 48)
            case .down:
                possiblePoint = CGPoint(x: self.position.x, y: self.position.y - 48)
            }
            
            if availableSpace.contains(possiblePoint) == false {
                possibleDirection.remove(at: possibleDirection.firstIndex(of: direction)!)
            }
        }
        
        if let newDirection = possibleDirection.randomElement(){
            var randomPoint: CGPoint = .zero
            switch newDirection {
            case .left:
                randomPoint = CGPoint(x: self.position.x - 48, y: self.position.y)
            case .right:
                randomPoint = CGPoint(x: self.position.x + 48, y: self.position.y)
            case .up:
                randomPoint = CGPoint(x: self.position.x, y: self.position.y + 48)
            case .down:
                randomPoint = CGPoint(x: self.position.x, y: self.position.y - 48)
            }
            self.direction = newDirection
            return randomPoint
        } else {
            fatalError("A random target could not be chosen")
        }
    }
    
    private func adjustSpeed(proposedLocation: CGPoint) -> CGFloat {
        var isInTunnel: Bool = false
        if proposedLocation.y == 984 {
            if proposedLocation.x >= 120 && proposedLocation.x <= 360 {
                isInTunnel = true
            } else if self.position.x >= 1176 && self.position.x <= 1416{
                isInTunnel = true
            }
        } else {
            isInTunnel = false
        }
        
        if isInTunnel {
            return levelData.ghostTunnelSpeed
        } else if self.isElroy1 {
            return levelData.elroy1Speed
        } else if self.isElroy2 {
            return levelData.elroy2Speed
        } else {
            return self.state == .frightened ? levelData.ghostFrightSpeed : levelData.ghostNormalSpeed
        }
    }
    
    private func adjustTexture(){
        let textureMovement: SKAction
        switch self.state {
        case .waiting, .ready, .escaping, .chase, .scatter:
            textureMovement = SKAction.repeatForever(SKAction.animate(with: [SKTexture(imageNamed: "\(self.name ?? "Someone")-A-\(direction.rawValue)"), SKTexture(imageNamed: "\(self.name ?? "Someone")-B-\(direction.rawValue)")], timePerFrame: 0.15))
        case .frightened:
            textureMovement = SKAction.repeatForever(SKAction.animate(with: [SKTexture(imageNamed: "Frightened-A"), SKTexture(imageNamed: "Frightened-B")], timePerFrame: 0.15))
        case .eaten:
            textureMovement = SKAction.repeatForever(SKAction.animate(with: [SKTexture(imageNamed: "Eaten-\(direction.rawValue)")], timePerFrame: 0.15))
        }
        self.run(textureMovement)
    }
}
