//
//  ImageGallery.swift
//  ImageGallery
//
//  Created by Alex Yatsenko on 13.05.2020.
//  Copyright © 2020 Alexislog's Production. All rights reserved.
//

import Foundation

struct ImageGallery: Codable {
    
    var images = [Image]()
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init() {
        self.images = [Image]()
    }
    
    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(ImageGallery.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
}
