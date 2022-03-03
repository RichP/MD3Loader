//
//  MD3Animations.swift
//  MD3Loader
//
//  Created by Richard Pickup on 28/02/2022.
//

import Foundation


struct AnimationInfo {
    let name: String
    var startFrame: Int
    var numFrames: Int
    let loopingFrames: Int
    let fps: Int
}

enum Animation: Int {
    case bothDeath1 = 0
    case bothDead1 = 1
    case bothDeath2 = 2
    case bothDead2 = 3
    case bothDeath3 = 4
    case bothDead3 = 5
    
    case torsoGesture = 6
    case torsoAttack = 7
    case torsoAttack2 = 8
    case torsoDrop = 9
    case torsoRaise = 10
    case torsoStand = 11
    case torsoStand2 = 12
    
    case legsWalkCR = 13
    case legsWalk = 14
    case legsRun = 15
    case legsBack = 16
    case legsSwim = 17
    case legsJump = 18
    case legsLand = 19
    case legsJumpB = 20
    case legsLandB = 21
    case legsIdle = 22
    case legsIdleCR = 23
    case legsTurn = 24
    
    var name: String {
        switch self {
        case .bothDeath1:
            return "BOTH_DEATH1"
        case .bothDead1:
            return "BOTH_DEAD1"
        case .bothDeath2:
            return "BOTH_DEATH2"
        case .bothDead2:
            return "BOTH_DEAD2"
        case .bothDeath3:
            return "BOTH_DEATH3"
        case .bothDead3:
            return "BOTH_DEAD3"
            
        case .torsoGesture:
            return "TORSO_GESTURE"
        case .torsoAttack:
            return "TORSO_ATTACK"
        case .torsoAttack2:
            return "TORSO_ATTACK2"
        case .torsoDrop:
            return "TORSO_DROP"
        case .torsoRaise:
            return "TORSO_RAISE"
        case .torsoStand:
            return "TORSO_STAND"
        case .torsoStand2:
            return "TORSO_STAND2"
        
        case .legsWalkCR:
            return "LEGS_WALKCR"
        case .legsWalk:
            return "LEGS_WALK"
        case .legsRun:
            return "LEGS_RUN"
        case .legsBack:
            return "LEGS_BACK"
        case .legsSwim:
            return "LEGS_SWIM"
        case .legsJump:
            return "LEGS_JUMP"
        case .legsLand:
            return "LEGS_LAND"
        case .legsJumpB:
            return "LEGS_JUMPB"
        case .legsLandB:
            return "LEGS_LANDB"
        case .legsIdle:
            return "LEGS_IDLE"
        case .legsIdleCR:
            return "LEGS_IDLECR"
        case .legsTurn:
            return "LEGS_TURN"
        }
    }
}
