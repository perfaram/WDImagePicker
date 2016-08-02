//
//  WDResizableCropOverlayView.swift
//  WDImagePicker
//
//  Created by Wu Di on 27/8/15.
//  Copyright (c) 2015 Wu Di. All rights reserved.
//

import UIKit

private struct WDResizableViewBorderMultiplyer {
    var widthMultiplyer: CGFloat!
    var heightMultiplyer: CGFloat!
    var xMultiplyer: CGFloat!
    var yMultiplyer: CGFloat!
}

internal class WDResizableCropOverlayView: WDImageCropOverlayView {
    private let kBorderCorrectionValue: CGFloat = 12

    var contentView: UIView!
    var cropBorderView: WDCropBorderView!

    private var initialContentSize = CGSize(width: 0, height: 0)
    private var resizingEnabled: Bool!
    private var anchor: CGPoint!
    private var startPoint: CGPoint!
    private var resizeMultiplyer = WDResizableViewBorderMultiplyer()
    private var lockAspectRatio: Bool = false

    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            super.frame = newValue

            let toolbarSize = CGFloat(UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 0 : 54)
            let width = self.bounds.size.width
            let height = self.bounds.size.height

            contentView?.frame = CGRectMake((
                width - initialContentSize.width) / 2,
                (height - toolbarSize - initialContentSize.height) / 2,
                initialContentSize.width,
                initialContentSize.height)

            cropBorderView?.frame = CGRectMake(
                (width - initialContentSize.width) / 2 - kBorderCorrectionValue,
                (height - toolbarSize - initialContentSize.height) / 2 - kBorderCorrectionValue,
                initialContentSize.width + kBorderCorrectionValue * 2,
                initialContentSize.height + kBorderCorrectionValue * 2)
        }
    }

    init(frame: CGRect, initialContentSize: CGSize, lockAspectRatio locked: Bool = false) {
        super.init(frame: frame)
        self.lockAspectRatio = locked
        self.initialContentSize = initialContentSize
        self.addContentViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let touchPoint = touch.locationInView(cropBorderView)

            anchor = self.calculateAnchorBorder(touchPoint)
            fillMultiplyer()
            resizingEnabled = true
            startPoint = touch.locationInView(self.superview)
        }
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            if resizingEnabled! {
                self.resizeWithTouchPoint(touch.locationInView(self.superview))
            }
        }
    }

    override func drawRect(rect: CGRect) {
        //fill outer rect
        UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).set()
        UIRectFill(self.bounds)

        //fill inner rect
        UIColor.clearColor().set()
        UIRectFill(self.contentView.frame)
    }

    private func addContentViews() {
        let toolbarSize = CGFloat(UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 0 : 54)
        let width = self.bounds.size.width
        let height = self.bounds.size.height

        contentView = UIView(frame: CGRectMake((
            width - initialContentSize.width) / 2,
            (height - toolbarSize - initialContentSize.height) / 2,
            initialContentSize.width,
            initialContentSize.height))
        contentView.backgroundColor = UIColor.clearColor()
        self.cropSize = contentView.frame.size
        self.addSubview(contentView)

        cropBorderView = WDCropBorderView(frame: CGRectMake(
            (width - initialContentSize.width) / 2 - kBorderCorrectionValue,
            (height - toolbarSize - initialContentSize.height) / 2 - kBorderCorrectionValue,
            initialContentSize.width + kBorderCorrectionValue * 2,
            initialContentSize.height + kBorderCorrectionValue * 2), lockAspectRatio: self.lockAspectRatio)
        self.addSubview(cropBorderView)
    }

    private func calculateAnchorBorder(anchorPoint: CGPoint) -> CGPoint {
        let allHandles = getAllCurrentHandlePositions()
        var closest: CGFloat = 3000
        var anchor: CGPoint!

        for handlePoint in allHandles {
            // Pythagoras is watching you :-)
            let xDist = handlePoint.x - anchorPoint.x
            let yDist = handlePoint.y - anchorPoint.y
            let dist = sqrt(xDist * xDist + yDist * yDist)

            closest = dist < closest ? dist : closest
            anchor = closest == dist ? handlePoint : anchor
        }

        return anchor
    }

    private func getAllCurrentHandlePositions() -> [CGPoint] {
        let leftX: CGFloat = 0
        let rightX = cropBorderView.bounds.size.width
        let centerX = leftX + (rightX - leftX) / 2

        let topY: CGFloat = 0
        let bottomY = cropBorderView.bounds.size.height
        let middleY = topY + (bottomY - topY) / 2

        var handleArray = [CGPoint]()
        handleArray.append(CGPointMake(leftX, topY)) //top left
        handleArray.append(CGPointMake(rightX, topY)) //top right
        handleArray.append(CGPointMake(rightX, bottomY)) //bottom right
        handleArray.append(CGPointMake(leftX, bottomY)) //bottom left

        if !lockAspectRatio {
            handleArray.append(CGPointMake(centerX, topY)) //top center
            handleArray.append(CGPointMake(rightX, middleY)) //middle right
            handleArray.append(CGPointMake(centerX, bottomY)) //bottom center
            handleArray.append(CGPointMake(leftX, middleY)) //middle left
        }

        return handleArray
    }

    private func resizeWithTouchPoint(point: CGPoint) {
        // This is the place where all the magic happends
        // prevent goint offscreen...

        let border = kBorderCorrectionValue * 2
        var pointX = point.x < border ? border : point.x
        var pointY = point.y < border ? border : point.y
        pointX = pointX > self.superview!.bounds.size.width - border ?
            self.superview!.bounds.size.width - border : pointX
        pointY = pointY > self.superview!.bounds.size.height - border ?
            self.superview!.bounds.size.height - border : pointY

        var heightChange = (pointY - startPoint.y) * resizeMultiplyer.heightMultiplyer
        var widthChange = (startPoint.x - pointX) * resizeMultiplyer.widthMultiplyer

        if lockAspectRatio {
            let averageChange = (heightChange + widthChange) / 2
            heightChange = averageChange
            widthChange = averageChange
        }

        let xChange = -1 * widthChange * resizeMultiplyer.xMultiplyer
        let yChange = -1 * heightChange * resizeMultiplyer.yMultiplyer


        var newFrame =  CGRectMake(
            cropBorderView.frame.origin.x + xChange,
            cropBorderView.frame.origin.y + yChange,
            cropBorderView.frame.size.width + widthChange,
            cropBorderView.frame.size.height + heightChange);
        newFrame = self.preventBorderFrameFromGettingTooSmallOrTooBig(newFrame)
        self.resetFrame(to: newFrame)
        startPoint = CGPointMake(pointX, pointY)
    }

    private func preventBorderFrameFromGettingTooSmallOrTooBig(frame: CGRect) -> CGRect {
        let toolbarSize = CGFloat(UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 0 : 54)
        var newFrame = frame

        if newFrame.size.width < 64 {
            newFrame.size.width = cropBorderView.frame.size.width
            newFrame.origin.x = cropBorderView.frame.origin.x
            if lockAspectRatio {
                newFrame.size.height = cropBorderView.frame.size.height
                newFrame.origin.y = cropBorderView.frame.origin.y
            }
        }

        if newFrame.size.height < 64 {
            newFrame.size.height = cropBorderView.frame.size.height
            newFrame.origin.y = cropBorderView.frame.origin.y
            if lockAspectRatio {
                newFrame.size.width = cropBorderView.frame.size.width
                newFrame.origin.x = cropBorderView.frame.origin.x
            }
        }

        if newFrame.origin.x < 0 {
            newFrame.size.width = cropBorderView.frame.size.width +
                (cropBorderView.frame.origin.x - self.superview!.bounds.origin.x)
            newFrame.origin.x = 0
            if lockAspectRatio {
                newFrame.size.height = cropBorderView.frame.size.height +
                    (cropBorderView.frame.origin.y - self.superview!.bounds.origin.y)
                newFrame.origin.y = 0
            }
        }

        if newFrame.origin.y < 0 {
            newFrame.size.height = cropBorderView.frame.size.height +
                (cropBorderView.frame.origin.y - self.superview!.bounds.origin.y)
            newFrame.origin.y = 0
            if lockAspectRatio {
                newFrame.size.width = cropBorderView.frame.size.width +
                    (cropBorderView.frame.origin.x - self.superview!.bounds.origin.x)
                newFrame.origin.x = 0
            }
        }

        if newFrame.size.width + newFrame.origin.x > self.frame.size.width {
            if lockAspectRatio {
                newFrame.size.width = cropBorderView.frame.size.width
                newFrame.size.height = cropBorderView.frame.size.height
            }
            else {
                newFrame.size.width = self.frame.size.width - cropBorderView.frame.origin.x
            }
        }

        if newFrame.size.height + newFrame.origin.y > self.frame.size.height - toolbarSize {
            if lockAspectRatio {
                newFrame.size.width = cropBorderView.frame.size.width
                newFrame.size.height = cropBorderView.frame.size.height
            }
            else {
                newFrame.size.height = self.frame.size.height -
                    cropBorderView.frame.origin.y - toolbarSize
            }
        }

        return newFrame
    }

    private func resetFrame(to frame: CGRect) {
        cropBorderView.frame = frame
        contentView.frame = CGRectInset(frame, kBorderCorrectionValue, kBorderCorrectionValue)
        cropSize = contentView.frame.size
        self.setNeedsDisplay()
        cropBorderView.setNeedsDisplay()
    }

    private func fillMultiplyer() {
        // -1 left, 0 middle, 1 right
        resizeMultiplyer.heightMultiplyer = anchor.y == 0 ?
            -1 : anchor.y == cropBorderView.bounds.size.height ? 1 : 0
        // -1 up, 0 middle, 1 down
        resizeMultiplyer.widthMultiplyer = anchor.x == 0 ?
            1 : anchor.x == cropBorderView.bounds.size.width ? -1 : 0
        // 1 left, 0 middle, 0 right
        resizeMultiplyer.xMultiplyer = anchor.x == 0 ? 1 : 0
        // 1 up, 0 middle, 0 down
        resizeMultiplyer.yMultiplyer = anchor.y == 0 ? 1 : 0
    }
}