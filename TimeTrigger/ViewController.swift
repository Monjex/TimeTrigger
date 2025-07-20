//
//  ViewController.swift
//  TimeTrigger
//
//  Created by HIGH ETHICS on 20/07/25.
//
 
import UIKit
import UserNotifications
import Foundation

class ViewController: UIViewController {

    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    var timer: Timer?
    var endDate: Date?

    let hours = Array(0...23)
    let minutes = Array(0...59)
    let seconds = Array(0...59)

    var selectedHour = 0
    var selectedMinute = 0
    var selectedSecond = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        initialUI()
        pickerView.dataSource = self
        pickerView.delegate = self
        requestNotificationPermission()
        restoreIfTimerRunning()
    }

    func initialUI() {
        countdownLabel.attributedText = formattedCountdown(hours: 0, minutes: 0, seconds: 0)
        startButton.layer.cornerRadius = 12
        stopButton.layer.cornerRadius = 12
        startButton.layer.borderWidth = 2
        stopButton.layer.borderWidth = 2
        startButton.layer.borderColor = UIColor.systemBlue.cgColor
        stopButton.layer.borderColor = UIColor.systemBlue.cgColor
    }

    @IBAction func startTapped(_ sender: UIButton) {
        let duration = TimeInterval(selectedHour * 3600 + selectedMinute * 60 + selectedSecond)
        guard duration >= 300 && duration <= 5400 else {
            showInvalidDurationAlert()
            return
        }

        endDate = Date().addingTimeInterval(duration)
        UserDefaults.standard.set(endDate, forKey: "endDate")

        startTimer()
        scheduleNotification(in: duration)
        pickerView.isHidden = true
        updateCountdown()
    }

    @IBAction func stopTapped(_ sender: UIButton) {
        stopTimer()
        countdownLabel.attributedText = formattedCountdown(hours: 0, minutes: 0, seconds: 0)
        pickerView.isHidden = false
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UserDefaults.standard.removeObject(forKey: "endDate")
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.updateCountdown()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    func updateCountdown() {
        guard let end = endDate else { return }
        let remaining = end.timeIntervalSinceNow

        if remaining <= 0 {
            countdownLabel.attributedText = formattedCountdown(hours: 0, minutes: 0, seconds: 0)
            stopTimer()
            showCompletionAlert()
            pickerView.isHidden = false
            UserDefaults.standard.removeObject(forKey: "endDate")
        } else {
            let remainingSeconds = Int(remaining)
            let hours = remainingSeconds / 3600
            let minutes = (remainingSeconds % 3600) / 60
            let seconds = remainingSeconds % 60
            countdownLabel.attributedText = formattedCountdown(hours: hours, minutes: minutes, seconds: seconds)
        }
    }

    func formattedCountdown(hours: Int, minutes: Int, seconds: Int) -> NSAttributedString {
        let attributed = NSMutableAttributedString()
        let numberFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        let labelFont = UIFont.systemFont(ofSize: 20, weight: .regular)

        func append(_ number: Int, label: String) {
            let numStr = String(format: "%02d", number)
            attributed.append(NSAttributedString(string: numStr, attributes: [.font: numberFont]))
            attributed.append(NSAttributedString(string: " \(label)   ", attributes: [.font: labelFont]))
        }

        append(hours, label: "hours")
        append(minutes, label: "min")
        append(seconds, label: "sec")

        return attributed
    }
    
    func scheduleNotification(in seconds: TimeInterval){
        let content = UNMutableNotificationContent()
        content.title = "⏰ Timer Completed!"
        content.body = "Your countdown has ended."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "timerDone", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func showCompletionAlert() {
        let alert = UIAlertController(title: "Done", message: "Timer completed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func restoreIfTimerRunning() {
        if let savedEnd = UserDefaults.standard.object(forKey: "endDate") as? Date {
            if savedEnd > Date() {
                endDate = savedEnd
                startTimer()
                pickerView.isHidden = true
                updateCountdown()
            } else {
                UserDefaults.standard.removeObject(forKey: "endDate")
            }
        }
    }

    func showInvalidDurationAlert() {
        let alert = UIAlertController(
            title: "Invalid Duration",
            message: "Please select a duration between 5 minutes and 1.5 hours.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return hours.count
        case 1: return minutes.count
        case 2: return seconds.count
        default: return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0: return "\(hours[row]) h"
        case 1: return "\(minutes[row]) m"
        case 2: return "\(seconds[row]) s"
        default: return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0: selectedHour = hours[row]
        case 1: selectedMinute = minutes[row]
        case 2: selectedSecond = seconds[row]
        default: break
        }
    }
}
