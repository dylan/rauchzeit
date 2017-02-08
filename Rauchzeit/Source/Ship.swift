//
//  Ship.swift
//  Rauchzeit
//
//  Created by Dylan Wreggelsworth on 2/8/17.
//  Copyright © 2017 BVR, LLC. All rights reserved.
//

public struct Ship {
    public enum Tier: UInt {
        case i      = 1
        case ii     = 2
        case iii    = 3
        case iv     = 4
        case v      = 5
        case vi     = 6
        case vii    = 7
        case viii   = 8
        case ix     = 9
        case x      = 10

        public var numeral: String {
            switch self {
            case .i:
                return "I"
            case .ii:
                return "II"
            case .iii:
                return "III"
            case .iv:
                return "IV"
            case .v:
                return "V"
            case .vi:
                return "VI"
            case .vii:
                return "VII"
            case .viii:
                return "VIII"
            case .ix:
                return "IX"
            case .x:
                return "X"
            }
        }
    }

    public enum Class: String {
        case cruiser    = "cruiser"
        case destroyer  = "destroyer"
    }

    public enum Nation: String {
        case commonWealth = "Commonwealth of Nations"
        case ussr         = "U.S.S.R."
        case usa          = "United States"
        case panAsia      = "Pan-Asia"
        case germany      = "Germany"
        case poland       = "Poland"
        case japan        = "Imperial Japanese Navy"
        case uk           = "United Kingdom"
    }

    public struct Smoke {
        let id: UInt
        let `class`: Ship.Class
        let cooldown1: UInt
        let cooldown2: UInt
        let emissionTime: UInt

        public init?(json: [String: Any]) {
            guard let jsonClass         = json["class"] as? String,
                  let classEnum         = Ship.Class(rawValue: jsonClass),
                  let jsonID            = json["id"] as? UInt,
                  let jsonCooldown1     = json["coolDown1"] as? UInt,
                  let jsonCooldown2     = json["coolDown2"] as? UInt,
                  let jsonEmissionTime  = json["emissionTime"] as? UInt else {
                    return nil
            }
            self.id      = jsonID
            self.`class` = classEnum
            cooldown1    = jsonCooldown1
            cooldown2    = jsonCooldown2
            emissionTime = jsonEmissionTime
        }
    }


    public let name: String
    public let nation: Ship.Nation
    public let tier: Ship.Tier
    public let smoke: Ship.Smoke
    public let `class`: Ship.Class
}
