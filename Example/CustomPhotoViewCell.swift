//
//  CustomPhotoViewCell.swift
//  Example
//
//  Created by Shaw on 9/19/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import UIKit
import SlidingPhoto

final class CustomPhotoViewCell: SlidingPhotoViewCell {
    let progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = CGRect(origin: .zero, size: CGSize(width: 40, height: 40))
        layer.cornerRadius = 20
        layer.lineWidth = 4
        layer.lineCap = .round
        layer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.strokeStart = 0
        layer.strokeEnd = 0
        layer.path = UIBezierPath(roundedRect: layer.bounds.insetBy(dx: 7, dy: 7), cornerRadius: layer.cornerRadius - 7).cgPath
        layer.isHidden = true
        return layer
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if nil == progressLayer.superlayer {
            layer.addSublayer(progressLayer)
        }
        progressLayer.position = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0)
    }
}
