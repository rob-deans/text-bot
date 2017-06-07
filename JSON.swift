//
//  JSON.swift
//  text-bot
//
//  Created by Robert Deans on 05/06/2017.
//
//

import SwiftyJSON

protocol JSONConvertor {
    init(context: [String:Any])
    func toJSON() -> JSON
}

public typealias JSONDictionary = [String: Any]
