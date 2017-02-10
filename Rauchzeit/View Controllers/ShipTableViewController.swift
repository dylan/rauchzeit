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
    private let bag = DisposeBag()

    let dataSource = RxTableViewSectionedReloadDataSource<ShipSection>()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sharedInit()
    }

    func sharedInit() {
        guard let parent = self.presentingViewController as? ViewController,
              let localModel = parent.model else {
            return
        }

        dataSource.configureCell = { ds, tv, ip, item in
            let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: ip)
            cell.textLabel?.text = "\(item.name)"
            cell.detailTextLabel?.text = "\(item.smoke.durationTime)s"
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

        _ = tableView.rx.itemSelected
            .asObservable()
            .subscribe(onNext: { [weak self] in
                guard let vc = self?.presentingViewController as? ViewController else {
                    return
                }
                vc.currentShip.value = sections[$0.section].items[$0.row]
                vc.dismiss(animated: true)
            }).addDisposableTo(bag)
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor(colorLiteralRed: 164/255, green: 59/255, blue: 60/255, alpha: 1.0)
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = tableView.backgroundColor
        header.backgroundView = UIView(frame: header.bounds)
        header.backgroundView?.backgroundColor = view.tintColor
    }

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = tableView.tintColor
        cell?.textLabel?.textColor = tableView.backgroundColor
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = tableView.tintColor
        cell?.textLabel?.textColor = tableView.backgroundColor
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

}
