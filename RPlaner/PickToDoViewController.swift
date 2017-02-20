//
//  PickToDoViewController.swift
//  RPlaner
//
//  Created by Zedd on 2017. 2. 10..
//  Copyright © 2017년 Zedd. All rights reserved.
//

import UIKit
import GameplayKit
import RealmSwift
import UserNotifications

private let stopTimeKey = "stopTimeKey"

class PickToDoViewController: UIViewController {
    
    let realm = try? Realm()
    var currentTime = NSDate()
    var todoList = ToDoList()
    var todo: ToDo?
    var startClickTime : Int = 0
    var endTime : Int = 0
    var randomIndex:Int?
    let userDefaults = UserDefaults.standard
   
    private var stopTime: Date?
  
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var circularProgressView: KDCircularProgress!
    
    var currentCount =  0.0
    var maxCount =  0.0
    var timers : Timer?
    func handle()
    {
        if maxCount <= currentCount{
            print("tttttttttt")
            circularProgressView.animate(toAngle: 0.0, duration: 1, completion: nil)
            timers?.invalidate()
            timers = nil
            
        }
        else{
            let newAngleValue = newAngle()
            circularProgressView.animate(toAngle:Double(newAngleValue), duration: 1, completion: nil)
        }
    }



    override func viewDidLoad() {
        super.viewDidLoad()
        
       

        
        completionButton.isHidden = true
        self.todoList.items = realm?.objects(ToDo.self)
        userDefaults.set(displayTodoLabel.text, forKey: "displayTodoLabel")
        
        if let doingTodo = todoList.items?.filter({ $0.isDoing == true }).first{
            displayTodoLabel.text = doingTodo.planTitle
            completionButton.isHidden = false
            pickRandomToDoButton.isHidden = true
            timeLabel.isHidden = false
            
            
            registerForLocalNotifications()
            stopTime = UserDefaults.standard.object(forKey: stopTimeKey) as? Date
            if let time = stopTime {
                if time > Date() {
                    startTimer(time, includeNotification: false)
                } else {
                    notifyTimerCompleted()
                }
            }
            
            
        }
            
        else{
            userDefaults.set(displayTodoLabel.text, forKey: "displayTodoLabel")
            displayTodoLabel.text = displayTodoLabel.text
            //timeLabel.isHidden = true
            
        }
        
    }
  
    
    private func registerForLocalNotifications() {
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                guard granted && error == nil else {
                    // display error
                    print("\(error)")
                    return
                }
            }
        }
        else {
            let types: UIUserNotificationType = [.badge, .sound, .alert]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
    
    @IBOutlet weak var displayTodoLabel: UILabel!
    @IBOutlet weak var pickRandomToDoButton: UIButton!
    @IBOutlet weak var completionButton: UIButton!
    
    
    @IBAction func tapPickRandomToDoButton(_ sender: Any) {
        timeLabel.isHidden = false
        if (todoList.items?.count)! >  0
        {
            
            currentCount = 0.0
            while  true{
                let ccount = realm?.objects(ToDo.self).filter("isComplete == true")
                if ccount?.count == todoList.items?.count{
                    timeLabel.isHidden = true
                    
                    displayTodoLabel.text = "모든 계획이 완료"
                    break;
                }
                self.randomIndex = Int(arc4random_uniform(UInt32((todoList.items?.count)!)))
                if((todoList.items?[randomIndex!].isComplete)! == false){
                    timeLabel.isHidden = false
                    displayTodoLabel.isHidden = false
                    displayTodoLabel.text = todoList.items?[randomIndex!].planTitle
                    pickRandomToDoButton.isHidden = true
                    completionButton.isHidden = false
                    
                    var deadLine = Double((todoList.items?[randomIndex!].deadLineNumber)!)
                    print(deadLine)
                    
                    
                   
                    let time = getCurrentDate() + (deadLine!*86400)
                    
                    maxCount = deadLine!*86400
                    //maxCount = 15.0
                    userDefaults.set(maxCount, forKey: "maxCount")
                    userDefaults.synchronize()

                    if currentCount != maxCount {
                        //currentCount += 1
                        
                        userDefaults.synchronize()
                        let newAngleValue = newAngle()
                        
                        //timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.handle(_:)), userInfo: nil, repeats: true)
                        timers = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                            self.handle()
                            //print("A")
                        })
                    }
                    else{
                        timers?.invalidate()
                        timers = nil
                    }


                    
                    
                    //let time = getCurrentDate() + 5.0
                   
                    print(time)
                    if time > Date() {
                        startTimer(time)
                    } else {
                        timeLabel.text = "timer date must be in future"
                    }
                    
                  
                    let realm = try! Realm()
                    realm.beginWrite()
                    todoList.items?[randomIndex!].isDoing = true
                    try? realm.commitWrite()
                    userDefaults.setValue(randomIndex, forKey: "randomIndex")
                    userDefaults.synchronize()
                    break
                }
                else{
                    continue
                }
            }
            
        }
        else{
            
            displayTodoLabel.isHidden = false
            displayTodoLabel.text = "계획을 먼저 생성해 주세요ㅠㅠ"
            timeLabel.isHidden = true
        }
    }
   
    func newAngle() -> Int {
        if currentCount >=  maxCount{
            timers?.invalidate()
            timers = nil
            currentCount = 0
            circularProgressView.animate(toAngle: 0, duration: 1, completion: nil)
            circularProgressView.animate(fromAngle:circularProgressView.angle, toAngle: 0, duration: 0.5, completion: nil)
        }

        currentCount += 1
        userDefaults.set(currentCount, forKey: "currentCount")
        userDefaults.synchronize()
        
        return Int(360 * (currentCount / maxCount))
    }

    func getCurrentDate() -> Date {
        
        var now:Date = Date()
        var calendar = Calendar.current
        let timezone = NSTimeZone.system
        calendar.timeZone = timezone
        //timezone을 사용해서 date의 components를 지정해서 가져옴.
        let anchorComponets = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: now)
        
        let getDateFromDateComponents = calendar.date(from: anchorComponets)
        if let getCurrentDate = getDateFromDateComponents {
            now = getCurrentDate
        }
        return now
    }
    
    @IBAction func tapToDoCompleteButton(_ sender: Any) {
        
        
        timeLabel.isHidden = true
        if let doingTodo = todoList.items?.filter({ $0.isDoing == true }).first{
            completionButton.isHidden = true
            pickRandomToDoButton.isHidden = false
            timeLabel.isHidden = true
            displayTodoLabel.text = "다음 계획을 생성하려면 클릭버튼을 눌러주세요"
            timeLabel.isHidden = true
            currentCount = 0
            circularProgressView.animate( toAngle: 0, duration: 1, completion: nil)
            
            
            
            let realm = try! Realm()
            realm.beginWrite()
            
            //todoList.complete()
            doingTodo.isComplete = true
            
            
            doingTodo.isDoing = false
            try? realm.commitWrite()
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timeLabel.isHidden = true
        
        if let doingTodo = todoList.items?.filter({ $0.isDoing == true }).first {
            
            
            if doingTodo.isComplete == false{
                self.displayTodoLabel.text = doingTodo.planTitle
                pickRandomToDoButton.isHidden = true
                completionButton.isHidden = false
                timeLabel.isHidden = false
                currentCount = userDefaults.double(forKey: "currentCount")
                userDefaults.synchronize()
                maxCount = userDefaults.double(forKey: "maxCount")
                userDefaults.synchronize()
                
                if currentCount != 0{
                    timers = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                        self.handle()
                    })
                }
                if currentCount >=  maxCount{
                    timers?.invalidate()
                    timers = nil
                    currentCount = 0
                    circularProgressView.animate(toAngle: 0, duration: 1, completion: nil)
                }

                
                
            }
            
            
        }
        else{
            
//            displayTodoLabel.text = userDefaults.string(forKey: "displayTodoLabel")
//            
//            if displayTodoLabel.text == "삭제된 계획입니다"{
//                displayTodoLabel.text = "다음 계획을 생성하려면 클릭버튼을 눌러주세요"
//                displayTodoLabel.text = userDefaults.string(forKey: "displayTodoLabel")
//                
//                userDefaults.synchronize()
//                return
//            }
//            
//            if displayTodoLabel.text == "삭제된 계획입니다"{
//                self.displayTodoLabel.text = "모든 계획이 완료"
//                displayTodoLabel.text = userDefaults.string(forKey: "displayTodoLabel")
//                userDefaults.synchronize()
//                return
//            }
//            else{
                self.displayTodoLabel.text = "삭제된 계획입니다"
                pickRandomToDoButton.isHidden = false
                completionButton.isHidden = true
                
            }
            
        }
        
    
    
    private var timer: Timer?
    
    private func startTimer(_ stopTime: Date, includeNotification: Bool = true) {
        // save `stopTime` in case app is terminated
        
        UserDefaults.standard.set(stopTime, forKey: stopTimeKey)
        self.stopTime = stopTime
        
        // start Timer
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handleTimer(_:)), userInfo: nil, repeats: true)
        
        guard includeNotification else { return }
        
        // start local notification (so we're notified if timer expires while app is not running)
        
        if #available(iOS 10, *) {
            let content = UNMutableNotificationContent()
            content.title = "계획기한이 만료되었어요."
            content.body = "다음 계획을 진행해보세요!"
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: stopTime.timeIntervalSinceNow, repeats: false)
            let notification = UNNotificationRequest(identifier: "timer", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(notification)
        } else {
            let notification = UILocalNotification()
            notification.fireDate = stopTime
            notification.alertBody = "Timer finished!"
            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private let dateComponentsFormatter: DateComponentsFormatter = {
        let _formatter = DateComponentsFormatter()
        _formatter.allowedUnits = [.day, .hour, .minute, .second]
        _formatter.unitsStyle = .abbreviated
        _formatter.zeroFormattingBehavior = .pad
        return _formatter
    }()
    
  
    
    func handleTimer(_ timer: Timer) {
        let now = Date()
        
        if stopTime! > now {
            timeLabel.text = dateComponentsFormatter.string(from: now, to: stopTime!)
        } else {
            stopTimer()
            notifyTimerCompleted()
        }
    }
    
    private func notifyTimerCompleted() {
        timeLabel.text = "Timer done!"
    }
    
}
