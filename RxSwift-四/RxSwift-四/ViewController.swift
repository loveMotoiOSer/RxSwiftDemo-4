//
//  ViewController.swift
//  RxSwift-四
//
//  Created by Soul on 2023/5/2.
//

import UIKit
import RxCocoa
import RxSwift

class ViewController: UIViewController {
    
    @IBOutlet weak var birthdayPicker: UIDatePicker!
    @IBOutlet weak var maleBtn: UIButton!
    @IBOutlet weak var femaleBtn: UIButton!
    @IBOutlet weak var knowSwiftSwitch: UISwitch!
    @IBOutlet weak var swiftLevelSlider: UISlider!
    @IBOutlet weak var passionToLearnStepper: UIStepper!
    @IBOutlet weak var heartHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var updateBtn: UIButton!
    
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        //出生日期不能超过今天，否则边框变色
        let birthdayOb = birthdayPicker.rx.date
            .map{NSObject.isValidDate(date: $0)} //判断日期是否超过今天
        birthdayOb.map{$0 ? UIColor.red: UIColor.clear} //超过今天返回红色，没超过则无色
            .subscribe { color in
                self.birthdayPicker.layer.borderColor = color.cgColor
            }
            .disposed(by: disposeBag)
        
        
        
        //性别选择按钮的背后的逻辑：
        // 1 : 性别的选择 和 上面生日的选择 决定下面更新按钮 : 我们常见的必选项
        // 2 : 性别的选择 是由我们的两个按钮进行处理，没必要分开逻辑
        let genderSeleteOb = BehaviorRelay<MGGender>(value: .notSelected)
        
        maleBtn.rx.tap
            .map{MGGender.male} //男 序列
            .bind(to: genderSeleteOb) //绑定自定义序列
            .disposed(by: disposeBag)
        
        femaleBtn.rx.tap
            .map {MGGender.female} //女 序列
            .bind(to: genderSeleteOb) //绑定自定义序列
            .disposed(by: disposeBag)
        
        genderSeleteOb.subscribe { gender in
            if gender == .notSelected {return}
            let isMale = gender == .male
            self.maleBtn.setImage(UIImage(named: isMale ? "check": "uncheck"), for: .normal)
            self.femaleBtn.setImage(UIImage(named: isMale ? "uncheck": "check"), for: .normal)
        }
        .disposed(by: disposeBag)

        
        // 按钮点击 - 常规思维需要给一个变量记录
        // Rx思维 应该是绑定到相应的序列里面去
        // 这个序列就是我们的 genderSelectionOb : male female notSelected ...枚举的值
        let genderSelOB = genderSeleteOb.map {$0 != .notSelected}

        Observable.combineLatest(birthdayOb, genderSelOB) { !$0 && $1 }
            .bind(to: updateBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        
        
        // 其他控件
        /**
         对UISwitch来说：
         当UISwitch为OFF时，表示用户不了解Swift，因此，下面的UISlider应该为0；
         当UISwitch为ON时，可以默认把UISlider设置在1/4的位置，表示大致了解；
         
         对于UISlider来说：
         当UISlider不为0时，应该自动把UISwitch设置为ON；
         当UISlider为0时，应该自动把UISwitch设置为OFF；
         */
        
        knowSwiftSwitch.rx.value.map {$0 ? 0.25 : 0}
            .bind(to: swiftLevelSlider.rx.value)
            .disposed(by: disposeBag)
        
        swiftLevelSlider.rx.value.map {$0 > 0 ? true : false}
            .bind(to: knowSwiftSwitch.rx.value)
            .disposed(by: disposeBag)
        
        
        
        //爱心大小
        passionToLearnStepper.rx.value.skip(1)
            .subscribe { value in
                UIView .animate(withDuration: 1) {
                    self.heartHeightConstraint.constant = value * 10
                    self.view.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)
    }
}


extension NSObject {
    //日期是否小于当天
    class func isValidDate(date: Date) -> Bool {
        let calendar = NSCalendar.current
        let compare = calendar.compare(date, to: Date.init(), toGranularity: .day)
        return compare == .orderedDescending
    }
}

enum MGGender {
    case notSelected
    case male
    case female
}
