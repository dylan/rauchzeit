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
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {
    private let bag = DisposeBag()

    public let model = Model()
    public var currentShip = Variable<Ship?>(nil)

    private var isOn: Bool = false

    private var startTime: TimeInterval = 0.0
    private var endTime: TimeInterval   = 0.0
    private var timeObserver: Disposable?

    @IBOutlet weak var choiceButton: UIButton!
    @IBOutlet weak var clockView: UIView!
    @IBOutlet weak var clockFace: UILabel!
    @IBOutlet weak var settingsButton: UIButton!

    var oneTone: AVAudioPlayer!
    var twoTone: AVAudioPlayer!
    var eightTone: AVAudioPlayer!

    var halfwayPointPlayed = false
    var endPlayed = false
    var startPlayed = false



    var shouldVibrate: Bool {
        return UserDefaults.standard.value(forKey: "vibrate") as? Bool ?? true
    }

    var shouldTone: Bool {
        return UserDefaults.standard.value(forKey: "tone") as? Bool ?? true
    }

    var preventSleep: Bool {
        return UserDefaults.standard.value(forKey: "preventSleep") as? Bool ?? false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = preventSleep
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        updateClockFace(with: 0.0)

        let oneToneUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "1-tone", ofType: "caf")!)
        let twoToneUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "2-tones", ofType: "caf")!)
        let eightToneUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "8-tones", ofType: "caf")!)
        do {
            oneTone = try AVAudioPlayer(contentsOf: oneToneUrl)
            twoTone = try AVAudioPlayer(contentsOf: twoToneUrl)
            eightTone = try AVAudioPlayer(contentsOf: eightToneUrl)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        prepAudio()

        currentShip.asObservable().subscribe({ [weak self] in
            guard case .next(let element) = $0,
                  let ship = element else {
                    return

            }
            self?.timeObserver?.dispose()

            self?.choiceButton.setTitle(ship.name, for: UIControlState.normal)

            self?.updateClockFace(with: Double(ship.smoke.durationTime))

        }).addDisposableTo(bag)

        clockView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    func handleTap(sender: UITapGestureRecognizer) {
        guard let ship = currentShip.value else {
            return
        }

        halfwayPointPlayed = false
        knock()

        stopAudio()
        timeObserver?.dispose()

        startTime = NSDate().timeIntervalSince1970
        endTime = Double(ship.smoke.durationTime) + startTime
        let duration = Double(endTime - startTime)

        updateClockFace(with: duration)

        if isOn == false {
            timeObserver = Observable<Int>.interval(0.075, scheduler: MainScheduler.instance).subscribe(tick)
            isOn = true
        } else {
            isOn = false
        }
    }

    func stopAudio() {
        eightTone.stop()
        eightTone.currentTime = 0

        twoTone.stop()
        twoTone.currentTime = 0

        oneTone.stop()
        oneTone.currentTime = 0
    }

    func prepAudio() {
        eightTone.prepareToPlay()
        twoTone.prepareToPlay()
        oneTone.prepareToPlay()
    }

    func tick(event: Event<Int>) -> Void {
        guard let ship = currentShip.value else {
            return
        }

        var duration = Double(endTime - NSDate().timeIntervalSince1970)

        if duration <= 0 {
            duration = Double(ship.smoke.durationTime)
            timeObserver?.dispose()
            isOn = false

            if shouldTone {
                eightTone.play()
            }

            knock(type: .error)
            flash(3)
        }

        if duration < Double(ship.smoke.durationTime / 2) && halfwayPointPlayed == false {
            halfwayPointPlayed = true

            if shouldTone {
                twoTone.play()
            }

            knock(type: .warning)
            flash(2)
        }

        updateClockFace(with: duration)
    }

    func updateClockFace(with duration: TimeInterval) {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [ .minute, .second ]
        formatter.zeroFormattingBehavior = [ .pad ]
        clockFace.text = formatter.string(from: duration)
    }

    func knock(type: UINotificationFeedbackType = .success) {
        guard shouldVibrate else {
            return
        }

        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(type)
        
        let supportLevel = UIDevice.current.value(forKey: "_feedbackSupportLevel") as! UInt
        if  supportLevel == 1 {
            switch type {
            case .success:
                AudioServicesPlaySystemSound(1519)
            case .warning:
                AudioServicesPlaySystemSound(1520)
            case .error:
                AudioServicesPlaySystemSound(1521)
            }
        } else if supportLevel != 2 {
            switch type {
            case .success:
                vibrate(1)
            case .warning:
                vibrate(2)
            case .error:
                vibrate(3)
            }
        }
    }

    var vibrateCounter: UInt = 0
    func vibrate(_ times: UInt) {
        vibrateCounter = times
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] timer in
            guard let vibrateCount = self?.vibrateCounter,  vibrateCount != 0 else {
                timer.invalidate()
                return
            }
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            self?.vibrateCounter -= 1
        }
    }

    var flashCounter: UInt = 0
    var flashOn = false
    func flash(_ times: UInt) {
        flashCounter = times
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let flashCount = self?.flashCounter,
                  let flashOn = self?.flashOn,
                  flashCount != 0 else {
                timer.invalidate()
                self?.clockFace.textColor = UIColor.white
                self?.flashOn = false
                return
            }
            if !flashOn {
                self?.clockFace.textColor = UIColor(red: 164/255, green: 59/255, blue: 60/255, alpha: 1.0)
                self?.flashOn = true
            } else {
                self?.clockFace.textColor = UIColor.white
                self?.flashOn = false
            }
            self?.flashCounter -= 1
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

