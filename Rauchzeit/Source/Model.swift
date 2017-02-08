//
//  JSON.swift
//  Rauchzeit
//
//  Created by Dylan Wreggelsworth on 2/8/17.
//  Copyright © 2017 BVR, LLC. All rights reserved.
//
import Foundation

public typealias JSON = [String: Any]

public struct Model {
    let values: JSON

    let smokes  : [Ship.Smoke]
    let nations : [Ship.Nation]
    let ships   : [Ship]
    let tiers   : [Ship.Tier]

    init? () {
        guard let jsonURL = Bundle.main.url(forResource: "Smoke", withExtension: "json"),
              let inputStream = InputStream(url: jsonURL) else {
                fatalError("Unable to load local json!")
        }

        inputStream.open()
        values = try! JSONSerialization.jsonObject(with: inputStream, options: .allowFragments) as! JSON
        inputStream.close()

        guard let jsonSmokes  = values["smoke"] as? [[String: Any]],
              let jsonNations = values["nations"] as? [[String: Any]] else {
                return nil
        }
        smokes = jsonSmokes
                    .map({ Ship.Smoke(json: $0) })
                    .flatMap({ $0 })

        nations = jsonNations
                    .map({
                        guard let jsonNation = $0["name"] as? String else { return nil }
                        return Ship.Nation(rawValue: jsonNation)
                    })
                    .flatMap({ $0 })

        var tempShips: [Ship] = []
        for value in jsonNations {
            guard let jsonNation = value["name"] as? String,
                  let nation     = Ship.Nation(rawValue: jsonNation),
                  let jsonShips  = value["ships"] as? [[String: Any]] else {
                    continue
            }
            for ship in jsonShips {
                guard let smokeID   = ship["smoke"] as? UInt,
                      let name      = ship["name"] as? String,
                      let jsonClass = ship["class"] as? String,
                      let shipClass = Ship.Class(rawValue: jsonClass),
                      let jsonTier  = ship["tier"] as? UInt,
                      let tier      = Ship.Tier(rawValue: jsonTier),
                      let smoke     = smokes.filter({ $0.id == smokeID && $0.`class` == shipClass}).first else {
                        continue
                }

                tempShips.append(Ship(name: name, nation: nation, tier: tier, smoke: smoke, class: shipClass))
            }
        }

        tempShips.sort { (ship1, ship2) -> Bool in
            return ship1.nation.rawValue < ship2.nation.rawValue
        }

        ships = tempShips

        tiers = Array(Set(tempShips.map({ return $0.tier }))).sorted(by: { tier1, tier2 in
            return tier1.rawValue < tier2.rawValue
        })
//        dump(smokes)
//        dump(nations)
//        dump(ships)
//        dump(tiers)
    }
}
