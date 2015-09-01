//
//  AKImageCropperView.swift
//  AKImageCropper
//
//  Created by Krachulov Artem
//  Copyright (c) 2015 Krachulov Artem. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import UIKit

@objc protocol AKImageCropperDelegate {
    
    optional func cropperViewDidScroll(scrollView: UIScrollView)
    optional func cropperViewDidZoom(scrollView: UIScrollView)
    optional func croperViewDidChangeCropRect(cropRect: CGRect, translatedToImageRect imageRect: CGRect)
}

class AKImageCropperView: UIView {
    
    // MARK: - Properties
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    var image: UIImage! {
        get {
            
            return viewsInitializated ? imageView.image : nil
        }
        set(image) {
            
            if image != nil {
                
                // Scroll View
                scrollView.contentSize = image.size
                
                // Image View
                imageView.image = image
                imageView.frame.size = image.size
                
                // Update Sizes
                refresh ()
            }
        }
    }
    var cropRect: CGRect {
        
        return getCropRects().cropRect
    }
    
    var cropImageRect: CGRect {
        
        return getCropRects().imageRect
    }
    
    
    // Configuring cropper view
    var cropFrameAnimationDuration: NSTimeInterval = 0.3
    var cropFrameAnimationOptions: UIViewAnimationOptions = .CurveEaseOut
    
    // Configuring overlay view with crop frame
    var fingerSize: CGFloat = 30.0
    var grid: Bool = true
    var gridLines: Int8 = 3
    
    var overlayColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    var strokeColor = UIColor.whiteColor()
    var cornerColor = UIColor.whiteColor()
    var gridColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
    
    // Managing the Delegate
    weak var delegate: AKImageCropperDelegate?
    
    
    // MARK: - Properties
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    private var overlay: AKImageCropperOverlay!
    
    private var offset: CGFloat {
        return cropFrameWillShow ? fingerSize / 2 : 0
    }
    
    // Hierarchy
    //
    //  - - - AKImageCropperView - - - - - - - -
    // |                                         |
    // |   - - - Aspect View - - - - - - - - -   |
    // |  |                                   |  |
    // |  |   - - - Scroll View - - - - - -   |  |
    // |  |  |                             |  |  |
    // |  |  |   - - - Image View - - -    |  |  |
    // |  |  |  |                       |  |  |  |
    // |  |  |  |                       |  |  |  |
    // |  |  |  |                       |  |  |  |
    // |  |  |  |                       |  |  |  |
    // |  |  |  |                       |  |  |  |
    // |  |  |  |                       |  |  |  |
    // |  |  |  |                       |  |  |  |
    // |  |  |  |                       |  |  |  |
    // |  |  |  | _ _ _ _ _ _ _ _ _ _ _ |  |  |  |
    // |  |  |                             |  |  |
    // |  |  | _ _ _ _ _ _ _ _ _ _ _ _ _ _ |  |  |
    // |  |                                   |  |
    // |  | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |  |
    // |                                         |
    // | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |
    
    private var aspectView: UIView!
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!

    
    // MARK: - Properties
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    private (set) var cropFrameIsActive = false
    
    // Flags

    // Блокирует новое действие пока не завершится текущее
    private var viewsInitializated = false
    
    // Блокирует новое действие пока не завершится текущее
    private var cropFrameAnimationActive = false
    
    // Используется для определения размера отступа рамки
    private var cropFrameWillShow = false
    
    // Испольльзуется анимация рамки в тукушьй момент или нет
    private var cropFrameTransitionWithAnimation = true
    

    // MARK: - Initialization
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    /*init () {
        super.init(frame:CGRectZero)
        
        create(nil, showCropFrame: false)
    }*/
    

    init(image: UIImage, showCropFrame: Bool) {
        
        super.init(frame:CGRectZero)
        
        create(image, showCropFrame: showCropFrame)
    
    }
    
    init(frame: CGRect, image: UIImage, showCropFrame: Bool) {
        
        super.init(frame: frame)
        
        create(image, showCropFrame: showCropFrame)


    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        create(nil, showCropFrame: false)
        
        #if DEBUG
            println("init(coder aDecoder: NSCoder)")
            println(" ")
        #endif
    }
    
    private func create(image: UIImage!, showCropFrame: Bool) {
        
        if viewsInitializated == false {
            
            self.backgroundColor = UIColor.clearColor()
            
            // Aspect View
            aspectView = UIView()
            aspectView.backgroundColor = UIColor.clearColor()
            aspectView.clipsToBounds = false
            
            self.addSubview(aspectView)
            
            
        
            
            // Scroll View
            scrollView = UIScrollView()
            scrollView.backgroundColor = UIColor.clearColor()
            scrollView.delegate = self
            scrollView.clipsToBounds = true
            scrollView.maximumZoomScale = 1
            
            aspectView.addSubview(scrollView)
            
            
            // Image View
            imageView = UIImageView()
            imageView.backgroundColor = UIColor.clearColor()
            imageView.userInteractionEnabled = true
            scrollView.addSubview(imageView)
            
            
            overlay = AKImageCropperOverlay()
            overlay.delegate = self
            
            // Send settings
            overlay.superView = self
            aspectView.addSubview(overlay)
            
            
            viewsInitializated = true
            
            self.image = image
            
            if showCropFrame {
                
                self.showOverlayViewAnimated(false, withCropFrame: nil, completion: nil)
            }
        }
    }
    
    func refresh() {
        
        let views = getViews()
        
        if viewsInitializated && !cropFrameAnimationActive && views.aspect != aspectView.frame {
        
            #if DEBUG
                println("AKImageCropperView: refresh()")
                println("Aspect View Frame: \(views.aspect)")
                println("Scale View Frame: \(views.scale)")
                println(" ")
            #endif
        
            // Aspect View
            aspectView.frame = views.aspect
            
            // Scroll View
            scrollView.frame = views.scroll
            scrollView.minimumZoomScale = views.scale
            scrollView.zoomScale = views.scale
        
            if cropFrameIsActive {
                
                overlay.refresh()
            }
        }
    }
    
    func destroy() {
        
        self.removeFromSuperview()
    }
    
    // MARK: - Crop Frame
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    func showOverlayViewAnimated(flag: Bool, withCropFrame rect: CGRect!, completion: (() -> Void)?) {
        
        // Block multiple clicking
        if !cropFrameAnimationActive  {
            
            // Set new flags
            cropFrameAnimationActive = true
            cropFrameWillShow = true
            cropFrameTransitionWithAnimation = flag
            
            // Init Overlay View

            
            self.viewWillTransition(nil) { () -> Void in
                
                println(self.aspectView.frame)
                
                let overlayRect = CGRect(origin: CGPointZero, size: self.aspectView.frame.size)
                
//                let rect = CGRectMake(0, 0, 60, 60)
                
                // Create Overlay View
                self.overlay.frame = /*AKImageCropperOverlay(frame: overlayRect, animated: flag)*/ overlayRect
                self.overlay.hidden = false
                
                self.overlay.refresh()
                
                
                // Animate
                if flag {
                    
                    self.overlay.alpha = 0
                    
                    UIView.animateWithDuration(0.3,
                        animations: { () -> Void in
                            
                            self.overlay.alpha = 1
                        }
                    )
                }

                
                
                // Reset Flags
                self.cropFrameAnimationActive = false
                
                // Set status
                self.cropFrameIsActive = true
                
                if completion != nil { completion!() }
            }
        }
    }
    
    func dismissOverlayViewAnimated(flag: Bool, completion: (() -> Void)?) {
        
        // Block multiple clicking
        if !cropFrameAnimationActive  {
            
            // Set new flags
            cropFrameAnimationActive = true
            cropFrameWillShow = false
            cropFrameTransitionWithAnimation = flag
            
            // Destroy Overlay View
            overlay.destroy(animated: flag,
                completion: { () -> Void in
                    
                    self.viewWillTransition(nil) { () -> Void in
                        
                        // Reset Flags
                        self.cropFrameTransitionWithAnimation = true
                        self.cropFrameAnimationActive = false
                        
                        // Set status
                        self.cropFrameIsActive = false
                        
                        // Retutn handler
                        completion!()
                    }
                }
            )
        }
        
    }
    

    
    func setCropRect(rect: CGRect) {
        
        overlay.setCropFrame(rect)
    }
    
    
    
    private func getCropRects() -> (cropRect: CGRect, imageRect: CGRect) {
        
        var imageRect = CGRect()
        var cropRect = CGRect()
        
        if cropFrameIsActive {
            
            
            let cropFrame = overlay.getCropFrame()
            
            imageRect.origin.x = (scrollView.contentOffset.x + cropFrame.origin.x) / scrollView.zoomScale
            imageRect.origin.y = (scrollView.contentOffset.y + cropFrame.origin.y) / scrollView.zoomScale
            imageRect.size.width =  cropFrame.size.width / scrollView.zoomScale
            imageRect.size.height = cropFrame.size.height / scrollView.zoomScale
            
            
            
            
        } else {
            
            cropRect = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
            
            imageRect = CGRectMake(
                scrollView.contentOffset.x / scrollView.zoomScale,
                scrollView.contentOffset.y / scrollView.zoomScale,
                scrollView.frame.size.width / scrollView.zoomScale,
                scrollView.frame.size.height / scrollView.zoomScale)
        }
        
        return (cropRect, imageRect)
    }
    
    
    func croppedImage() -> UIImage {
        
        var cropRect = CGRect()
        
        if cropFrameIsActive {
            
            let cropFrame = overlay.getCropFrame()
            
            println(cropFrame)
                     
            cropRect.origin.x = (scrollView.contentOffset.x + cropFrame.origin.x) / scrollView.zoomScale
            cropRect.origin.y = (scrollView.contentOffset.y + cropFrame.origin.y) / scrollView.zoomScale
            cropRect.size.width =  cropFrame.size.width / scrollView.zoomScale
            cropRect.size.height = cropFrame.size.height / scrollView.zoomScale
            
            println(cropRect)
            
        
        } else {
            
            cropRect = CGRectMake(
                scrollView.contentOffset.x / scrollView.zoomScale,
                scrollView.contentOffset.y / scrollView.zoomScale,
                scrollView.frame.size.width / scrollView.zoomScale,
                scrollView.frame.size.height / scrollView.zoomScale)
        }
        
        var rect = CGRectMake(CGFloat(Int(cropRect.origin.x)), CGFloat(Int(cropRect.origin.y)), CGFloat(Int(cropRect.size.width)), CGFloat(Int(cropRect.size.height)))

        return image.getImageInRect(rect)
    }

    // MARK: - Helper Methods
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    private func getViews() -> (aspect: CGRect, scroll: CGRect, scale: CGFloat) {
        
        self.layoutIfNeeded()
        
        if let image = image {
            
            // Crop view with offset
            let viewWithOffset = CGRectInset(frame, offset, offset)
            
            var scale = CGRectFitScale(CGRect(origin: CGPointZero, size: image.size), toRect: viewWithOffset)
                scale = scale < 1 ? scale : 1
            
            let scaledSize = CGSizeMake(image.size.width * scale, image.size.height * scale)
            
            // Scale image with proportion
            let aspectSize = CGSizeMake(scaledSize.width + offset*2, scaledSize.height + offset*2)
            let aspect = CGRectCenters(CGRect(origin: CGPointZero, size: aspectSize), inRect: self.frame)
            
            var scroll = CGRect(origin: CGPointZero, size: aspectSize)
                scroll.inset(dx: offset, dy: offset)
            
            return (aspect, scroll, scale)
            
        } else {
            return (aspect: CGRectZero, scroll: CGRectZero, scale: 0)
        }
    }
    
    // MARK: - Rotate Animation
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    private func viewWillTransition(coordinator: UIViewControllerTransitionCoordinator!, completion:(() -> Void)?) {
        
        let views = getViews()
                    
        if (CGRectGetWidth(self.frame) - offset*2 > CGRectGetWidth(aspectView.frame) && CGRectGetHeight(self.frame) - offset*2 > CGRectGetHeight(aspectView.frame)) || cropFrameTransitionWithAnimation == false {
        
            aspectView.frame = views.aspect
            
            scrollView.frame = views.scroll
            scrollView.minimumZoomScale = views.scale
            scrollView.zoomScale = views.scale
            
            completion!()
            
        } else {
            
            println("AA")
            
            if self.overlay != nil {
                UIView.animateWithDuration(cropFrameAnimationDuration / 2,
                    animations: { () -> Void in
                        
                        self.overlay.alpha = 0
                    }
                )
            }
            
            UIView.animateWithDuration(cropFrameAnimationDuration, delay: 0.0, options: cropFrameAnimationOptions,
                animations: {
                
                    self.aspectView.frame = views.aspect
                    
                    self.scrollView.frame = views.scroll
                    self.scrollView.minimumZoomScale = views.scale
                    self.scrollView.zoomScale = views.scale

                },
                completion: { (finished) -> Void in
                    if finished {
                        
                        if coordinator != nil {
                            coordinator.animateAlongsideTransition(nil,
                                completion: { (context) -> Void in

                                    if self.overlay != nil {
                                        let overlay = CGRect(origin: CGPointZero, size: self.aspectView.frame.size)
                                        
                                        self.overlay.refresh()
                                        
//                                        self.overlay.frame = overlay
//                                        self.overlay.cropFrame = overlay
//                                        self.overlay.setCropFrame(<#frame: CGRect#>)
                                        
                                        UIView.animateWithDuration(self.cropFrameAnimationDuration,
                                            animations: { () -> Void in
                                                
                                                self.overlay.alpha = 1
                                            }
                                        )
                                    }
                                }
                            )
                        }
                        
                        completion!()
                    }
                }
            )
        }
    }
}

// MARK: - UIScrollViewDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKImageCropperView: UIScrollViewDelegate {
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}

// MARK: - AKImageCropperOverlayDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKImageCropperView: AKImageCropperOverlayDelegate {
    
    func pinchGesture(overlay: AKImageCropperOverlay, sender: UIPinchGestureRecognizer) {
        
        var scrollScale = sender.scale
        
        if scrollScale > 1 {
            
            var delta = sender.scale / 100
            scrollScale = (1 * delta) + 1
            
        } else {
            
            var delta = sender.scale / 50
            scrollScale = 1 - (1 * delta)
        }
        
        scrollView.zoomScale *= scrollScale
    }
    
    func panGesture(overlay: AKImageCropperOverlay, sender: UIPanGestureRecognizer) {
        
        let size = scrollView.contentSize
        let offset = scrollView.contentOffset
        let frame = scrollView.frame
        
        if size.height > frame.height || size.width > frame.width {
            
            var translation = sender.translationInView(overlay)
            
            scrollView.contentOffset.x -= translation.x
            scrollView.contentOffset.y -= translation.y
            
            if sender.state == .Ended {
                
                var newOffset = offset
                
                if size.width >= frame.width {
                    
                    var delta = size.width - frame.size.width
                    
                    
                    if offset.x < 0 {
                        
                        newOffset.x = 0
                    }
                    
                    if offset.x > delta {
                        newOffset.x = delta
                        
                    }
                }
                
                if size.height >= frame.height {
                    
                    var delta = size.height - frame.size.height
                    
                    if offset.y < 0 {
                        
                        newOffset.y = 0
                    }
                    
                    if offset.y > delta {
                        
                        newOffset.y = delta
                    }
                }
                
                UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseIn,
                    animations: { () -> Void in
                        
                        self.scrollView.contentOffset = newOffset
                    },
                    completion: nil
                )
                
            }
        }
    }

}


// MARK: - UIScrollViewDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKImageCropperView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        self.delegate?.cropperViewDidScroll?(scrollView)
        
        let rects = getCropRects()
        self.delegate?.croperViewDidChangeCropRect?(rects.cropRect, translatedToImageRect: rects.imageRect)
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        
        self.delegate?.cropperViewDidZoom?(scrollView)
    }
}