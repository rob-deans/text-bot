//
//  City.swift
//  text-bot
//
//  Created by Robert Deans on 05/06/2017.
//
//

import SwiftyJSON
import RestKit

class City: JSONConvertor {
    var alternate_name: String?
    var name: String?
    var number_of_states: Int?
    var states: [State]?
    
    required init(context: [String:Any]) {
        alternate_name = context["alternate_name"] as? String
        name = context["name"] as? String
        number_of_states = context["number_of_states"] as? Int
        states = context["states"] as? [State]
    }
    
    func toJSON() -> SwiftyJSON.JSON {
        var city: JSONDictionary = [:]
        
        city["alternate_name"] = self.alternate_name
        city["name"] = self.name
        city["number_of_states"] = self.number_of_states
        city["states"] = self.states
        
        return JSON(city)
    }
}
