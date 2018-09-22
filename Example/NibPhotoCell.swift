//
//  NibPhotoCell.swift
//  Example
//
//  Created by Shaw on 9/19/18.
//  Copyright © 2018 Shaw. All rights reserved.
//

import SlidingPhoto

final class NibPhotoCell: SlidingPhotoViewCell {
    static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
}

