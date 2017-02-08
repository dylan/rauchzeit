//
//  ShipTableViewController.swift
//  Rauchzeit
//
//  Created by Dylan Wreggelsworth on 2/8/17.
//  Copyright © 2017 BVR, LLC. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

struct ShipSection {
    var header: String
    var items: [Item]
}

extension ShipSection: SectionModelType {
    typealias Item = Ship
    init(original: ShipSection, items: [ShipSection.Item]) {
        self = original
        self.items = items
    }
}

final class ShipTableViewController: UITableViewController {

    let model = Model()
    let dataSource = RxTableViewSectionedReloadDataSource<ShipSection>()

    override func viewDidLoad() {
        super.viewDidLoad()
        sharedInit()
    }

    func sharedInit() {
        guard let localModel = model else {
            return
        }

        dataSource.configureCell = { ds, tv, ip, item in
            let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: ip)
            cell.textLabel?.text = "\(item.name)"
            return cell
        }

        dataSource.titleForHeaderInSection = { ds, index in
            return ds.sectionModels[index].header
        }

        var sections: [ShipSection] = []
        localModel.tiers.forEach { tier in
            let items = localModel.ships.filter({ $0.tier == tier })
            sections.append(ShipSection(header: tier.numeral, items: items))
        }

        _ = Observable.just(sections)
                      .bindTo(tableView.rx.items(dataSource: dataSource))

        _ = tableView.rx.itemSelected.subscribe({
            print($0)
        })
    }

}
