//
//  NLUExtension.swift
//  text-bot
//
//  Created by Robert Deans on 07/06/2017.
//
//

import Foundation
import NaturalLanguageUnderstandingV1
import CloudFoundryConfig

extension NaturalLanguageUnderstanding {
    
    public convenience init(service: NaturalLanguageUnderstandingService, version: String) {
        
        self.init(username: service.username, password: service.password, version: version)
        
    }
}
