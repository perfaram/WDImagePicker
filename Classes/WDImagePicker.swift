//
//  WDImagePicker.swift
//  WDImagePicker
//
//  Created by Wu Di on 27/8/15.
//  Copyright (c) 2015 Wu Di. All rights reserved.
//

import UIKit

@objc public protocol WDImagePickerDelegate {
    @objc optional func imagePicker(_ imagePicker: WDImagePicker, pickedImage: UIImage)
    //commented out while SR-2268 gets resolved
    //@objc optional func imagePicker(_ imagePicker: WDImagePicker, pickedRect: CGRect, onImage: UIImage)
    var prefersPickedImageRectangle: Bool { get }
    @objc optional func imagePickerDidCancel(_ imagePicker: WDImagePicker)
}

@objc public class WDImagePicker: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, WDImageCropControllerDelegate {
    public var delegate: WDImagePickerDelegate?
    public var cropSize: CGSize!
    public var resizableCropArea = false
    public var lockAspectRatio = false

    private var _imagePickerController: UIImagePickerController!
    private var chosenImage: UIImage?

    public var imagePickerController: UIImagePickerController {
        return _imagePickerController
    }
    
    override public init() {
        super.init()

        self.cropSize = CGSize(width: 320, height: 320)
        _imagePickerController = UIImagePickerController()
        _imagePickerController.delegate = self
        _imagePickerController.sourceType = .photoLibrary
    }

    private func hideController() {
        self._imagePickerController.dismiss(animated: true, completion: nil)
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if self.delegate?.imagePickerDidCancel != nil {
            self.delegate?.imagePickerDidCancel!(self)
        } else {
            self.hideController()
        }
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let cropController = WDImageCropViewController()
        chosenImage = (info[UIImagePickerControllerOriginalImage] as! UIImage)
        cropController.sourceImage = chosenImage!
        cropController.resizableCropArea = self.resizableCropArea
        cropController.lockAspectRatio = self.lockAspectRatio
        cropController.cropSize = self.cropSize
        cropController.delegate = self
        picker.pushViewController(cropController, animated: true)
    }

    func imageCropController(_ imageCropController: WDImageCropViewController, didFinishWithCroppedRect croppedRect: CGRect) {
        guard let chosenImage = chosenImage else { return } //should never happen, unless this function is called outside of WDImagePicker's process
        if let rectInsteadOfImage = delegate?.prefersPickedImageRectangle,  rectInsteadOfImage == true {
            //commented out while SR-2268 gets resolved
            //self.delegate?.imagePicker?(self, pickedRect: croppedRect, onImage: chosenImage)
        }
        else {
            // finally crop image
            let imageRef = chosenImage.cgImage?.cropping(to: croppedRect)
            let croppedImage = UIImage(cgImage: imageRef!, scale: chosenImage.scale,
                                       orientation: chosenImage.imageOrientation)
            self.delegate?.imagePicker?(self, pickedImage: croppedImage)
        }
    }
}
