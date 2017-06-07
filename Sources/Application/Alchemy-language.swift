//
//  Alchemy-language.swift
//  text-bot
//
//  Created by Robert Deans on 19/05/2017.
//
//

import Foundation
import NaturalLanguageUnderstandingV1

// Returns true if the entity is a city
func isCity(_ entity: EntitiesResult) -> Bool {
    return entity.type! == "Location"
}

// Returns only the name property
func onlyName(_ city: EntitiesResult) -> String {
    return city.text!
}

// Extract the city mentioned in the input text
func extractCity(text params: JSON, completion: @escaping (_ success: String?) -> Void) {
    // Alchemy lang
    let features = Features(entities: EntitiesOptions(limit: 1))
    let parameters  = Parameters(features: features, text: params["text"].string, language: "en")
    
    
    
    nlu?.analyzeContent(withParameters: parameters, failure: failure) { success in
        var city = success.entities?.filter(isCity).map(onlyName)
        completion((city?.count)! > 0 ? city?[0] : nil)
    }
}
