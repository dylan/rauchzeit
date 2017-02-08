//
//  ViewController.swift
//  Rauchzeit
//
//  Created by Dylan Wreggelsworth on 2/8/17.
//  Copyright © 2017 BVR, LLC. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    private let bag = DisposeBag()

    public let model = Model()
    public var currentShip = Variable<Ship?>(nil)

    private var startTime: TimeInterval = 0.0
    private var endTime: TimeInterval   = 0.0
    private var timeObserver: Disposable?

    @IBOutlet weak var choiceButton: UIButton!
    @IBOutlet weak var clockView: UIView!
    @IBOutlet weak var clockFace: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        choiceButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let vc = self?.storyboard?.instantiateViewController(withIdentifier: "ShipTableViewController") as? ShipTableViewController else {
                return
            }

            self?.present(vc, animated: true)
        }).addDisposableTo(bag)

        currentShip.asObservable().subscribe({ [weak self] in
            guard case .next(let element) = $0,
                  let ship = element else {
                    return
            }
            self?.choiceButton.setTitle(ship.name, for: UIControlState.normal)
        }).addDisposableTo(bag)

        self.setupGestures()
    }

    func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        clockView.addGestureRecognizer(tapGesture)
    }

    func handleTap(sender: UITapGestureRecognizer) {
        guard let ship = currentShip.value else {
            return
        }
        timeObserver?.dispose()

        startTime = NSDate().timeIntervalSince1970
        endTime = Double(ship.smoke.durationTime) + startTime
        let duration = Double(endTime - startTime)
        clockFace.text = String(format:"%.2f", duration)

        timeObserver = Observable<Int>.interval(0.05, scheduler: MainScheduler.instance)
            .subscribe({ [weak self] (event) in
                guard let weakSelf = self else {
                    return
                }
                let duration = Double(weakSelf.endTime - NSDate().timeIntervalSince1970)
                if duration > 0 {
                    weakSelf.clockFace.text = String(format:"%.2f", duration)
                } else {
                    weakSelf.clockFace.text = "0.0"
                    weakSelf.timeObserver?.dispose()
                }
            })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

