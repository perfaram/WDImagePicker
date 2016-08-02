//
//  WDCropBorderView.swift
//  WDImagePicker
//
//  Created by Wu Di on 27/8/15.
//  Copyright (c) 2015 Wu Di. All rights reserved.
//

import UIKit

internal class WDCropBorderView: UIView {
    private let kNumberOfBorderHandles: CGFloat = 8
    private let kHandleDiameter: CGFloat = 24
    private var lockAspectRatio: Bool

    convenience init(frame: CGRect, lockAspectRatio locked: Bool) {
        self.init(frame: frame)
        self.lockAspectRatio = locked
    }

    override init(frame: CGRect) {
        self.lockAspectRatio = false
        super.init(frame: frame)

        self.backgroundColor = UIColor.clearColor()
    }

    required init?(coder aDecoder: NSCoder) {
        self.lockAspectRatio = false
        super.init(coder: aDecoder)

        self.backgroundColor = UIColor.clearColor()
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        CGContextSetStrokeColorWithColor(context,
            UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).CGColor)
        CGContextSetLineWidth(context, 1.5)
        CGContextAddRect(context, CGRectMake(kHandleDiameter / 2, kHandleDiameter / 2,
            rect.size.width - kHandleDiameter, rect.size.height - kHandleDiameter))
        CGContextStrokePath(context)

        CGContextSetRGBFillColor(context, 1, 1, 1, 0.95)
        for handleRect in calculateAllNeededHandleRects() {
            CGContextFillEllipseInRect(context, handleRect)
        }
    }

    private func calculateAllNeededHandleRects() -> [CGRect] {

        let width = self.frame.width
        let height = self.frame.height

        let leftColX: CGFloat = 0
        let rightColX = width - kHandleDiameter
        let centerColX = rightColX / 2

        let topRowY: CGFloat = 0
        let bottomRowY = height - kHandleDiameter
        let middleRowY = bottomRowY / 2

        var handleArray = [CGRect]()
        handleArray.append(CGRectMake(leftColX, topRowY, kHandleDiameter, kHandleDiameter)) //top left
        handleArray.append(CGRectMake(rightColX, topRowY, kHandleDiameter, kHandleDiameter)) //top right
        handleArray.append(CGRectMake(rightColX, bottomRowY, kHandleDiameter, kHandleDiameter)) //bottom right
        handleArray.append(CGRectMake(leftColX, bottomRowY, kHandleDiameter, kHandleDiameter)) //bottom left

        if !lockAspectRatio {
            handleArray.append(CGRectMake(centerColX, topRowY, kHandleDiameter, kHandleDiameter)) //top center
            handleArray.append(CGRectMake(rightColX, middleRowY, kHandleDiameter, kHandleDiameter)) //middle right
            handleArray.append(CGRectMake(centerColX, bottomRowY, kHandleDiameter, kHandleDiameter)) //bottom center
            handleArray.append(CGRectMake(leftColX, middleRowY, kHandleDiameter, kHandleDiameter)) //middle left
        }

        return handleArray
    }
}