//
//  NKAttributeLabel.swift
//  NKAttributeLabel
//
//  Created by MC on 2020/8/16.
//  Copyright © 2020 聂康. All rights reserved.
//

import UIKit

protocol NKAttributeLabelDelegate: NSObjectProtocol {
    func didSelected(text: String, range: NSRange)
}

enum Pattern: String {
    case name = "@[\\u4e00-\\u9fa5a-zA-Z0-9_-]+"
    case url = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
}

class MatchPattern {
    var attributeText: NSMutableAttributedString? {
        didSet {
            matchRanges()
        }
    }
    var attributes: [NSAttributedString.Key: Any] = [:]
    var selectedColor: UIColor?
    private(set) var pattern: String = ""
    private(set) var ranges: [NSRange] = []
    
    init(pattern: String) {
        self.pattern = pattern
    }
    
    private func matchRanges()  {
        ranges.removeAll()
        guard let attr = attributeText,
            attr.length > 0 else {
           return
        }
//        //不区分字母大小写的模式
//        NSRegularExpression.Options.caseInsensitive
//        //忽略掉正则表达式中的空格和#号之后的字符
//        NSRegularExpression.Options.allowCommentsAndWhitespace
//        //将正则表达式整体作为字符串处理
//        NSRegularExpression.Options.ignoreMetacharacters
//        //允许.匹配任何字符，包括换行符
//        NSRegularExpression.Options.dotMatchesLineSeparators
//        //允许^和$符号匹配行的开头和结尾
//        NSRegularExpression.Options.anchorsMatchLines
//        //设置\n为唯一的行分隔符，否则所有的都有效
//        NSRegularExpression.Options.useUnixLineSeparators
//        //使用UnicodeTR#29标准作为词的边界，否则所有传统正则表达式的词边界都有效
//        NSRegularExpression.Options.useUnicodeWordBoundaries
        let range = NSRange(location: 0, length: attr.length)

        guard let reg = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .anchorsMatchLines]) else {
            return
        }
        let matches = reg.matches(in: attr.string, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: range)
        
        for match in matches {
            ranges.append(match.range)
            attr.addAttributes(attributes, range: match.range)
        }

    }
}


class NKAttributeLabel: UILabel {
    
    var patterns: [MatchPattern] = [] {
        didSet{
            guard patterns.count > 0 else {
                return
            }
            updateTextStorage()
        }
    }
    
    var selected: (NSRange, MatchPattern)?
    var selectedPattern: MatchPattern?
    
    weak var delegate: NKAttributeLabelDelegate?

    private var textStorage = NSTextStorage()
    private var layoutManager =  NSLayoutManager()
    private var textContainer = NSTextContainer()
    
    override var text: String? {
        didSet {
            updateTextStorage()
        }
    }
    
    override var attributedText: NSAttributedString? {
        didSet {
            updateTextStorage()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func updateTextStorage() {
        guard let attr = attributedText else {
            return
        }
        // 计算富文本
        let muAttr = NSMutableAttributedString(attributedString: attr)
        addLineBreak(muAttr)
        setMatchAttributes(muAttr)
        textStorage.setAttributedString(muAttr)
        setNeedsDisplay()
    }
    
    private func addLineBreak(_ attrString: NSMutableAttributedString) {
        if attrString.length == 0 {
            return
        }
        var range = NSRange(location: 0, length: 0)
        var attributes = attrString.attributes(at: 0, effectiveRange: &range)
        var paragraphStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle
        
        if paragraphStyle != nil {
            paragraphStyle!.lineBreakMode = NSLineBreakMode.byWordWrapping
        } else {
            // iOS 8.0 can not get the paragraphStyle directly
            paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle!.lineBreakMode = NSLineBreakMode.byWordWrapping
            attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
            attrString.setAttributes(attributes, range: range)
        }
    }

    private func setMatchAttributes(_ attrString: NSMutableAttributedString) {
        if attrString.length == 0 {
           return
        }
        var range = NSRange(location: 0, length: 0)
        var attributes = attrString.attributes(at: 0, effectiveRange: &range)
        attributes[NSAttributedString.Key.font] = font
        attributes[NSAttributedString.Key.foregroundColor] = textColor
        attributes[NSAttributedString.Key.backgroundColor] = backgroundColor
        
        attrString.addAttributes(attributes, range: range)
                
        for p in patterns {
            p.attributeText = attrString
        }
    }
        
    private func glyphRange() -> NSRange {
        return NSMakeRange(0, textStorage.length)
    }
    
    private func glyphsOffset(range: NSRange) -> CGPoint {
        let rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
        return CGPoint(x: 0, y: rect.origin.y)
    }
    
    override func draw(_ rect: CGRect) {
        let range = glyphRange()
        layoutManager.drawBackground(forGlyphRange: range, at: CGPoint.zero)
        layoutManager.drawGlyphs(forGlyphRange: range, at: CGPoint.zero)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textContainer.size = bounds.size
    }
}

extension NKAttributeLabel {
    
    private func selectedRangeChange(_ isCancel: Bool = false) {
        guard let (selectedRange, selectedPattern) = selected else { return }
        var attributes = textStorage.attributes(at: 0, effectiveRange: nil)
        if !isCancel {
            attributes[NSAttributedString.Key.backgroundColor] = selectedPattern.selectedColor
        } else {
            attributes[NSAttributedString.Key.backgroundColor] = UIColor.clear
            selected = nil
        }
        textStorage.addAttributes(attributes, range: selectedRange)
        setNeedsDisplay()
    }
    
    private func touchRange(location: CGPoint) -> (NSRange, MatchPattern)? {
        guard textStorage.length > 0 else { return nil }
        let offset = glyphsOffset(range: glyphRange())
        let point = CGPoint(x: offset.x + location.x, y: offset.y + location.y)
        let index = layoutManager.glyphIndex(for: point, in: textContainer)
        for p in patterns {
            for r in p.ranges {
                if index >= r.location && index <= r.location + r.length {
                    return (r, p)
                }
            }
        }
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else {
            return
        }
        selected = touchRange(location: location)
        selectedRangeChange()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self),
            let currentSelected = touchRange(location: location),
            let selected = selected else {
            selectedRangeChange(true)
            return
        }
        if currentSelected.0 == selected.0 {
            selectedRangeChange(true)
        }else {
            selectedRangeChange(true)
            self.selected = selected
            selectedRangeChange()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let selected = selected else { return }
        let range = selected.0
        let text = (textStorage.string as NSString).substring(with: range)
        delegate?.didSelected(text: text, range: range)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
            self.selectedRangeChange(true)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedRangeChange(true)
    }
}

extension NKAttributeLabel {
    func setup() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        isUserInteractionEnabled = true
    }
}
