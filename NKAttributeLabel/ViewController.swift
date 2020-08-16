//
//  ViewController.swift
//  NKAttributeLabel
//
//  Created by MC on 2020/8/16.
//  Copyright © 2020 聂康. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var label: NKAttributeLabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        label = NKAttributeLabel()
        label.attributedText = NSAttributedString(string: "http://www.baidu.com@小明  测试暗https://黑@ via还发了份half甲氨蝶呤减肥啦拉零售价单； 就按；就按积分；进度")
        label.frame = CGRect(x: 100, y: 100, width: 200, height: 300)
        label.delegate = self
        view.addSubview(label)
        
        let match = MatchPattern(pattern: Pattern.url.rawValue)
        match.attributes[NSAttributedString.Key.foregroundColor] = UIColor.blue
        match.selectedColor = UIColor.red
        label.patterns.append(match)
        // 匹配@
        let matchName = MatchPattern(pattern: Pattern.name.rawValue)
        matchName.attributes[NSAttributedString.Key.foregroundColor] = UIColor.purple
        matchName.selectedColor = UIColor.yellow
        label.patterns.append(matchName)
    }
}

extension ViewController : NKAttributeLabelDelegate {
    func didSelected(text: String, range: NSRange) {
        print(text)
        print(range)
    }
}

