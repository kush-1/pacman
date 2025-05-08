//
//  Constants.swift
//  PacMan
//
//  Kush Desai and James Park
//

import SpriteKit

// MARK: - ENUMERATIONS
enum Direction: String {
    case up = "up"
    case down = "down"
    case left = "left"
    case right = "right"
}

enum State{
    case waiting
    case ready
    case escaping
    case chase
    case scatter
    case frightened
    case eaten
}

// MARK - EXTENSION
extension SKShapeNode {
    convenience init(start: CGPoint, end: CGPoint, strokeColor: UIColor, lineWidth: CGFloat) {
        self.init()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: start.x, y: start.y))
        path.addLine(to: CGPoint(x: end.x, y: end.y))
        self.path = path
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }
}

// MARK: - CONSTANTS AND GLOBAL VARIABLES
var wallSpace: [CGPoint] = [CGPoint]()
var availableSpace: [CGPoint] = [CGPoint]()

let readyLabel: SKLabelNode = SKLabelNode(fontNamed: "Chalkboard")
let playerLabel: SKLabelNode = SKLabelNode(fontNamed: "Chalkboard")
let bonusLabel: SKLabelNode = SKLabelNode(fontNamed: "Chalkboard")

var arrayOfTimeForStateChange: [Double] = [Double]()

var levelData: Level = Level()

var level: Int = 0 {
    didSet {
        switch level {
        case 1:
            arrayOfTimeForStateChange = [7,20,7,20,5,20,5,86400]
        case 2...4:
            arrayOfTimeForStateChange = [7,20,7,20,5,1033,0,0.02,86400]
        default:
            arrayOfTimeForStateChange = [5,20,5,20,5,1037,0,0.02,86400]
        }
    }
}

let startPositions: [String: CGPoint] = [
    "Blinky": grindToCoord(column: 15, row: 23, xOffset: 24),
    "Pinky": grindToCoord(column: 15, row: 20, xOffset: 24),
    "Inky": grindToCoord(column: 13, row: 20, xOffset: 24),
    "Clyde": grindToCoord(column: 17, row: 20, xOffset: 24)
]

let scatterTargets: [String: CGPoint] = [
    "Blinky": grindToCoord(column: 28, row: 35),
    "Pinky": grindToCoord(column: 3, row: 35),
    "Inky": grindToCoord(column: 28, row: 3),
    "Clyde": grindToCoord(column: 3, row: 3)
]

var globalState: State = .scatter
var globalHoldState: State = .scatter

var totalDotsRemaining: Int = 0

// MARK: - GLOBAL METHODS
func grindToCoord(column: Int, row: Int, tileSize: CGSize = CGSize(width: 48, height: 48), xOffset: Double = 0) -> CGPoint {
    let xCoord: Double = Double(column) * tileSize.width + (tileSize.width / 2) + xOffset
    let yCoord: Double = Double(row) * tileSize.height + (tileSize.height / 2)
    return CGPoint(x: xCoord, y: yCoord)
}

func degToRad(degrees: Double) -> CGFloat {
    degrees * .pi / 180
}

// MARK: - ACTIONS
//pacman chomping
let chompSound: SKAction = SKAction.repeatForever(SKAction.playSoundFileNamed("pacman_chomp.wav", waitForCompletion: true))
let chomp: SKAction = SKAction.repeatForever(SKAction.animate(with: [SKTexture(imageNamed: "Pacman-Closed"), SKTexture(imageNamed: "Pacman-Opened")], timePerFrame: 0.15))
let chompGroup: SKAction = SKAction.group([chompSound, chomp])

let bonusEatenSound: SKAction = SKAction.playSoundFileNamed("pacman_eatfruit.wav", waitForCompletion: true)
let gameStartSound: SKAction = SKAction.playSoundFileNamed("pacman_beginning.wav", waitForCompletion: true)
let ghostEatenSound: SKAction = SKAction.playSoundFileNamed("pacman_eatghost.wav", waitForCompletion: true)


// pacman death :(

let deathsound: SKAction = SKAction.playSoundFileNamed("pacman_death.wav", waitForCompletion: true)
let death: SKAction = SKAction.animate(with: [SKTexture(imageNamed: "Pacman-Dying-1"), SKTexture(imageNamed: "Pacman-Dying-2"), SKTexture(imageNamed: "Pacman-Dying-3"), SKTexture(imageNamed: "Pacman-Dying-4"), SKTexture(imageNamed: "Pacman-Dying-5")], timePerFrame: 0.2)
let rotate: SKAction = SKAction.rotate(toAngle: degToRad(degrees: 0), duration: 0)
let pause: SKAction = SKAction.wait(forDuration: 0.5)
let remove: SKAction = SKAction.removeFromParent()
let deathGroup: SKAction = SKAction.group([deathsound, death])
let deathSequence: SKAction = SKAction.sequence([rotate, pause, deathGroup, pause, remove])

