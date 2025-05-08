//
//  Player.swift
//  PacMan
//
// Kush Desai and James Park
//

import SpriteKit

class Player: SKSpriteNode {
    
    // MARK: - PROPERTIES
    var isPlayerAlive: Bool = false
    var direction: Direction = .right
    var proposedDirection: Direction = .right
    var isAlignedToGrid: Bool = false
    var isMoving: Bool = false
    var pacSpeed: CGFloat = 0
    
    // MARK: - METHODS
    func create() {
        self.size = CGSize(width: 86, height: 86)
        self.position = CGPoint(x: 768, y: 552)
        self.texture = SKTexture(imageNamed: "Pacman-Opened")
        self.isPlayerAlive = true
        self.isAlignedToGrid = false
        self.name = "pacman"
    }
    
    func move() {
        // ensure pacman is aligned to the grid and on available space for movement
        guard self.isAlignedToGrid && availableSpace.contains(self.position) else {
            let alignWithGrid: SKAction = SKAction.move(to: CGPoint(x: 792, y: 552), duration: 0)
            self.run(alignWithGrid)
            self.isAlignedToGrid = true
            return
        }
        
        guard self.isMoving == false else {return}
        
        pacSpeed = globalState == .frightened ? levelData.pacFrightSpeed : levelData.pacNormalSpeed
        
        self.isMoving = true
        
        var newLocation: CGPoint = .zero
        var distanceFromPoint: Double = -1
        
        // see if proposed direction is available to move to
        for point in availableSpace {
            switch self.proposedDirection {
            case .up:
                if self.position.x == point.x && self.position.y < point.y && abs(self.position.y - point.y) <= 48{
                    distanceFromPoint = abs(self.position.y - point.y)
                    newLocation = point
                    self.direction = .up
                    self.run(SKAction.rotate(toAngle: degToRad(degrees: 90), duration: 0))
                }
            case .down:
                if self.position.x == point.x && self.position.y > point.y && abs(self.position.y - point.y) <= 48{
                    distanceFromPoint = abs(self.position.y - point.y)
                    newLocation = point
                    self.direction = .down
                    self.run(SKAction.rotate(toAngle: degToRad(degrees: 270), duration: 0))
                }
            case .left:
                if self.position.y == point.y && self.position.x > point.x && abs(self.position.x - point.x) <= 48{
                    distanceFromPoint = abs(self.position.x - point.x)
                    newLocation = point
                    self.direction = .left
                    self.run(SKAction.rotate(toAngle: degToRad(degrees: 180), duration: 0))
                }
            case .right:
                if self.position.y == point.y && self.position.x < point.x && abs(self.position.x - point.x) <= 48{
                    distanceFromPoint = abs(self.position.x - point.x)
                    newLocation = point
                    self.direction = .right
                    self.run(SKAction.rotate(toAngle: degToRad(degrees: 0), duration: 0))
                }
            }
        }
        
        // if newLocation is still .zero then the player couldnt move to the proposed direction
        // see if current direction is available to move to
        if newLocation == .zero {
            for point in availableSpace {
                switch self.direction {
                case .up:
                    if self.position.x == point.x && self.position.y < point.y && abs(self.position.y - point.y) <= 48{
                        distanceFromPoint = abs(self.position.y - point.y)
                        newLocation = point
                        self.direction = .up
                        self.run(SKAction.rotate(toAngle: degToRad(degrees: 90), duration: 0))
                    }
                case .down:
                    if self.position.x == point.x && self.position.y > point.y && abs(self.position.y - point.y) <= 48{
                        distanceFromPoint = abs(self.position.y - point.y)
                        newLocation = point
                        self.direction = .down
                        self.run(SKAction.rotate(toAngle: degToRad(degrees: 270), duration: 0))
                    }
                case .left:
                    if self.position.y == point.y && self.position.x > point.x && abs(self.position.x - point.x) <= 48{
                        distanceFromPoint = abs(self.position.x - point.x)
                        newLocation = point
                        self.direction = .left
                        self.run(SKAction.rotate(toAngle: degToRad(degrees: 180), duration: 0))
                    }
                case .right:
                    if self.position.y == point.y && self.position.x < point.x && abs(self.position.x - point.x) <= 48{
                        distanceFromPoint = abs(self.position.x - point.x)
                        newLocation = point
                        self.direction = .right
                        self.run(SKAction.rotate(toAngle: degToRad(degrees: 0), duration: 0))
                    }
                }
            }
        }
        
        // if newLocation is still .zero then there is nowhere to move
        // stop any movements
        if newLocation == .zero {
            if self.action(forKey: "pac-chomp") != nil {self.removeAction(forKey: "pac-chomp")}
            self.isMoving = false
        } else {
            if newLocation.x >= 1416 && self.direction == .right {
                newLocation.x = 120
                self.position = newLocation
                self.isMoving = false
            } else if newLocation.x <= 120 && self.direction == .left {
                newLocation.x = 1416
                self.position = newLocation
                self.isMoving = false
            } else {
                let move: SKAction = SKAction.move(to: newLocation, duration: CFTimeInterval(distanceFromPoint / self.pacSpeed))
                let stop: SKAction = SKAction.run {
                    self.isMoving = false
                }
                let sequence: SKAction = SKAction.sequence([move, stop])
                self.run(sequence)
                
                if self.action(forKey: "pac-chomp") == nil {self.run(chompGroup, withKey: "pac-chomp")}
            }
        }
    }
}
