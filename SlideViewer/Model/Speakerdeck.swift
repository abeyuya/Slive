//
//  Speakerdeck.swift
//  Slive
//
//  Created by abeyuya on 2018/01/17.
//  Copyright © 2018年 abeyuya. All rights reserved.
//

import Foundation

struct Slide: Codable {
    let thumb: String
    let preview: String
    let original: String
}

struct Talk: Codable {
    let slides: [Slide]
}
