//
//  Indicator.swift
//  Kingfisher
//
//  Created by João D. Moreira on 30/08/16.
//
//  Copyright (c) 2018 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if canImport(AppKit)
import AppKit
public typealias IndicatorView = NSView
#else
import UIKit
public typealias IndicatorView = UIView
#endif

/// Represents the activty indicator type which should be added to
/// an image view when an image is being downloaded.
///
/// - none: No indicator.
/// - activity: Uses the system activity indicator.
/// - image: Uses an image as indicator. GIF is supported.
/// - custom: Uses a custom indicator. The type of associated value should conform to the `Indicator` protocol.
public enum IndicatorType {
    /// No indicator.
    case none
    /// Uses the system activity indicator.
    case activity
    /// Uses an image as indicator. GIF is supported.
    case image(imageData: Data)
    /// Uses a custom indicator. The type of associated value should conform to the `Indicator` protocol.
    case custom(indicator: Indicator)
}

// MARK: - Indicator Protocol

/// An indicator type which can be used to show the download task is in progress.
public protocol Indicator {
    
    /// Called when the indicator should start animating.
    func startAnimatingView()
    
    /// Called when the indicator should stop animating.
    func stopAnimatingView()

    /// Center offset of the indicator. Kingfisher will use this value to determine the position of
    /// indicator in the super view.
    var centerOffset: CGPoint { get }
    
    /// The indicator view which would be added to the super view.
    var view: IndicatorView { get }
}

extension Indicator {
    
    /// Default implementation of `centerOffset` of `Indicator`. The default value is `.zero`, means that there is
    /// no offset for the indicator view.
    public var centerOffset: CGPoint { return .zero }
}

// MARK: - ActivityIndicator
// Displays a NSProgressIndicator / UIActivityIndicatorView
final class ActivityIndicator: Indicator {

    #if os(macOS)
    private let activityIndicatorView: NSProgressIndicator
    #else
    private let activityIndicatorView: UIActivityIndicatorView
    #endif
    private var animatingCount = 0

    var view: IndicatorView {
        return activityIndicatorView
    }

    func startAnimatingView() {
        if animatingCount == 0 {
            #if os(macOS)
            activityIndicatorView.startAnimation(nil)
            #else
            activityIndicatorView.startAnimating()
            #endif
            activityIndicatorView.isHidden = false
        }
        animatingCount += 1
    }

    func stopAnimatingView() {
        animatingCount = max(animatingCount - 1, 0)
        if animatingCount == 0 {
            #if os(macOS)
                activityIndicatorView.stopAnimation(nil)
            #else
                activityIndicatorView.stopAnimating()
            #endif
            activityIndicatorView.isHidden = true
        }
    }

    init() {
        #if os(macOS)
            activityIndicatorView = NSProgressIndicator(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
            activityIndicatorView.controlSize = .small
            activityIndicatorView.style = .spinning
        #else
            #if os(tvOS)
                let indicatorStyle = UIActivityIndicatorView.Style.white
            #else
                let indicatorStyle = UIActivityIndicatorView.Style.gray
            #endif
            #if swift(>=4.2)
            activityIndicatorView = UIActivityIndicatorView(style: indicatorStyle)
            #else
            activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: indicatorStyle)
            #endif
        #endif
    }
}

// MARK: - ImageIndicator
// Displays an ImageView. Supports gif
final class ImageIndicator: Indicator {
    private let animatedImageIndicatorView: ImageView

    var view: IndicatorView {
        return animatedImageIndicatorView
    }

    init?(
        imageData data: Data,
        processor: ImageProcessor = DefaultImageProcessor.default,
        options: KingfisherParsedOptionsInfo? = nil)
    {
        var options = options ?? KingfisherParsedOptionsInfo(nil)
        // Use normal image view to show animations, so we need to preload all animation data.
        if !options.preloadAllAnimationData {
            options.preloadAllAnimationData = true
        }
        
        guard let image = processor.process(item: .data(data), options: options) else {
            return nil
        }

        animatedImageIndicatorView = ImageView()
        animatedImageIndicatorView.image = image
        
        #if os(macOS)
            // Need for gif to animate on macOS
            animatedImageIndicatorView.imageScaling = .scaleNone
            animatedImageIndicatorView.canDrawSubviewsIntoLayer = true
        #else
            animatedImageIndicatorView.contentMode = .center
        #endif
    }

    func startAnimatingView() {
        #if os(macOS)
            animatedImageIndicatorView.animates = true
        #else
            animatedImageIndicatorView.startAnimating()
        #endif
        animatedImageIndicatorView.isHidden = false
    }

    func stopAnimatingView() {
        #if os(macOS)
            animatedImageIndicatorView.animates = false
        #else
            animatedImageIndicatorView.stopAnimating()
        #endif
        animatedImageIndicatorView.isHidden = true
    }
}