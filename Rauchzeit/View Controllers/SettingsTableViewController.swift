//
//  SettingsTableViewController.swift
//  Rauchzeit
//
//  Created by Dylan Wreggelsworth on 2/9/17.
//  Copyright © 2017 BVR, LLC. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class SettingsTableViewController: UITableViewController {

    private let bag = DisposeBag()

    @IBOutlet weak var vibrateWarningSwitch: UISwitch!
    @IBOutlet weak var toneWarningSwitch: UISwitch!
    @IBOutlet weak var preventSleepSwitch: UISwitch!

    override func viewDidLoad() {
        let navItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem = navItem

        let defaults = UserDefaults.standard
        if let tone = defaults.value(forKey: "tone") as? Bool {
            toneWarningSwitch.isOn = tone
        }
        if let vibrate = defaults.value(forKey: "vibrate") as? Bool {
            vibrateWarningSwitch.isOn = vibrate
        }
        if let preventSleep = defaults.value(forKey: "preventSleep") as? Bool {
            preventSleepSwitch.isOn = preventSleep
        }

        preventSleepSwitch.rx.isOn.subscribe( { event in
            guard let state = event.element else {
                return
            }
            defaults.set(state, forKey: "preventSleep")
        }).addDisposableTo(bag)

        vibrateWarningSwitch.rx.isOn.subscribe( { event in
            guard let state = event.element else {
                return
            }
            defaults.set(state, forKey: "vibrate")
        }).addDisposableTo(bag)

        toneWarningSwitch.rx.isOn.subscribe( { event in
            guard let state = event.element else {
                return
            }
            defaults.set(state, forKey: "tone")
        }).addDisposableTo(bag)
    }

    func done() {
        dismiss(animated: true)
    }
}
