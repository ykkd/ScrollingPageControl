//
//  ScrollingPageControl.swift
//  ScrollingPageControl
//
//  Created by Emilio Peláez on 3/10/18.
//

import UIKit

public protocol ScrollingPageControlDelegate: AnyObject {
    // If delegate is nil or the implementation returns nil for a given dot, the default
    // circle will be used. Returned views should react to having their tint color changed
    func viewForDot(at index: Int) -> UIView?
}

open class ScrollingPageControl: UIView {
    open weak var delegate: ScrollingPageControlDelegate? {
        didSet {
            createViews()
        }
    }
    
    // The number of dots
    open var pages: Int = 0 {
        didSet {
            guard pages != oldValue else { return }
            pages = max(0, pages)
            invalidateIntrinsicContentSize()
            createViews()
        }
    }
    
    private func createViews() {
        dotViews = (0..<pages).map { index in
            delegate?.viewForDot(at: index) ?? CircularView(frame: CGRect(origin: .zero, size: CGSize(width: dotSize, height: dotSize)))
        }
    }
    
    // The index of the currently selected page
    open var selectedPage: Int = 0 {
        didSet {
            guard selectedPage != oldValue else { return }
            selectedPage = max(0, min(selectedPage, pages - 1))
            
            // Detect circular navigation between first and last pages
            if oldValue == pages - 1 && selectedPage == 0 {
                pageOffset = 0
                centerOffset = 0
                updatePositions() // Reset to initial state
            } else if oldValue == 0 && selectedPage == pages - 1 {
                pageOffset = max(0, pages - maxDots)
                centerOffset = maxDots - centerDots
                updatePositions() // Reset to initial state
            } else {
                if (0..<centerDots).contains(selectedPage - pageOffset) {
                    centerOffset = selectedPage - pageOffset
                } else {
                    pageOffset = selectedPage - centerOffset
                }
            }
            
            // Update the colors of the selected dots
            updateColors()
        }
    }
    
    // The maximum number of dots that will show in the control
    open var maxDots = 7 {
        didSet {
            maxDots = max(3, maxDots)
            if maxDots % 2 == 0 {
                maxDots += 1
                print("maxDots has to be an odd number")
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    // The number of dots that will be centered and full-sized
    open var centerDots = 3 {
        didSet {
            centerDots = max(1, centerDots)
            if centerDots > maxDots {
                centerDots = maxDots
                print("centerDots has to be equal or smaller than maxDots")
            }
            if centerDots % 2 == 0 {
                centerDots += 1
                print("centerDots has to be an odd number")
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    // The duration, in seconds, of the dot slide animation
    open var slideDuration: TimeInterval = 0.15
    
    private var centerOffset = 0
	private var pageOffset = 0 {
	    didSet {
	        guard pageOffset != oldValue else { return }
	        UIView.animate(withDuration: slideDuration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
	            self?.updatePositions()
	        }, completion: nil)
	    }
	}
    
    internal var dotViews: [UIView] = [] {
        didSet {
            oldValue.forEach {
                if $0.superview == self {
                    $0.removeFromSuperview() // Safely remove views
                }
            }
            dotViews.forEach(addSubview)
            updateColors()
            setNeedsLayout()
        }
    }
    
    // The color of all the unselected dots
    open var dotColor = UIColor.lightGray { didSet { updateColors() } }
    // The color of the currently selected dot
    open var selectedColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1) { didSet { updateColors() } }
    
    // The size of the dots
    open var dotSize: CGFloat = 6 {
        didSet {
            dotSize = max(1, dotSize)
            dotViews.forEach { $0.frame = CGRect(origin: .zero, size: CGSize(width: dotSize, height: dotSize)) }
            invalidateIntrinsicContentSize()
        }
    }
    
    // The space between dots
    open var spacing: CGFloat = 4 {
        didSet {
            spacing = max(1, spacing)
            invalidateIntrinsicContentSize()
        }
    }
    
    public init() {
        super.init(frame: .zero)
        isOpaque = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }
    
    private var lastSize = CGSize.zero
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastSize else { return }
        lastSize = bounds.size
        updatePositions()
    }
    
    private func updateColors() {
        dotViews.enumerated().forEach { page, dot in
            dot.tintColor = page == selectedPage ? selectedColor : dotColor
        }
    }
    
    internal func updatePositions() {
        guard pages > 0 else { return }
        let centerDots = min(self.centerDots, pages)
        let maxDots = min(self.maxDots, pages)
        let sidePages = (maxDots - centerDots) / 2
        let horizontalOffset = max(0, CGFloat(-pageOffset + sidePages) * (dotSize + spacing) + (bounds.width - intrinsicContentSize.width) / 2)
        let centerPage = centerDots / 2 + pageOffset
        
        dotViews.enumerated().forEach { page, dot in
            let center = CGPoint(x: min(bounds.width - dotSize / 2, max(dotSize / 2, horizontalOffset + dotSize / 2 + (dotSize + spacing) * CGFloat(page))), y: bounds.midY)
            let distance = abs(page - centerPage)
            let scale: CGFloat = {
                if distance > (maxDots / 2) { return 0 }
                let scales: [CGFloat] = [1, 0.66, 0.33, 0.16]
                return scales[max(0, min(scales.count - 1, distance - centerDots / 2))]
            }()
            dot.frame = CGRect(origin: .zero, size: CGSize(width: dotSize * scale, height: dotSize * scale))
            dot.center = center
        }
    }
    
    open override var intrinsicContentSize: CGSize {
        let pages = min(maxDots, self.pages)
        let width = CGFloat(pages) * dotSize + CGFloat(pages - 1) * spacing
        let height = dotSize
        return CGSize(width: width, height: height)
    }
}
