//
//  GalleryTableViewCell.swift
//  ImageGallery
//
//  Created by Alex Yatsenko on 16.05.2020.
//  Copyright © 2020 Alexislog's Production. All rights reserved.
//

import UIKit

final class GalleryTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    var resignationHandler: (() -> Void)?
    
    @IBOutlet weak var titleTextField: UITextField! {
        didSet {
            titleTextField.delegate = self
            let tap = UITapGestureRecognizer(target: self, action: #selector(beginEditing))
            tap.numberOfTapsRequired = 2
            addGestureRecognizer(tap)
        }
    }
    
    @objc private func beginEditing() {
        titleTextField.isEnabled = true
        titleTextField.becomeFirstResponder()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        textField.isEnabled = false
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        resignationHandler?()
    }
}
