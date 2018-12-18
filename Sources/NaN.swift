//
//  NaN.swift
//  SlidingPhoto
//
//  Created by Shaw on 12/18/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import Foundation

public extension Double {
    func nanToZero() -> Double {
        return isNaN ? 0 : self
    }
}

public extension Float {
    func nanToZero() -> Float {
        return isNaN ? 0 : self
    }
}

public extension CGFloat {
    func nanToZero() -> CGFloat {
        return isNaN ? 0 : self
    }
}

public extension CGPoint {
    func nanToZero() -> CGPoint {
        if x.isNaN || y.isNaN {
            return CGPoint(x: x.nanToZero(), y: y.nanToZero())
        }
        return self
    }
}

public extension CGSize {
    func nanToZero() -> CGSize {
        if width.isNaN || height.isNaN {
            return CGSize(width: width.nanToZero(), height: height.nanToZero())
        }
        return self
    }
}

public extension CGRect {
    func nanToZero() -> CGRect {
        if minX.isNaN || minY.isNaN || width.isNaN || height.isNaN {
            return CGRect(x: minX.nanToZero(), y: minY.nanToZero(), width: width.nanToZero(), height: height.nanToZero())
        }
        return self
    }
}
