//
//  Weather.swift
//  text-bot
//
//  Created by Robert Deans on 19/05/2017.
//
//

import Foundation
import Kitura
import SwiftyJSON
import NaturalLanguageUnderstandingV1
import ConversationV1
import KituraRequest
import KituraNet
import RestKit

func getGeoLocation(city: String, completion: @escaping (_ data: [String:Any]?, _ error: Swift.Error?) -> Void ) {
    var qString: QueryString = [:]
    
    qString["query"] = city
    qString["locationType"] = "city"
    qString["countryCode"] = "US"
    qString["language"] = "en-US"
    
    // Make a request to the weather
    
    KituraRequest.request(.get, "https://twcservice.mybluemix.net/api/weather/v3/location/search", parameters: qString, headers: ["Authorization": "Basic ZWJiMDQyMmMtMTQ2Ny00YmQ2LTllNWItMWRhN2RlNzM0NzJmOnkxVUpXU01uSnA="]).response { request, response, data, error in
        
        //convert to json
        let json = JSON(data: data!)
        
        var statesByCity: [String: Any] = [:]
        
        switch json["location"]["adminDistrict"].object {
        case let adminDistricts as Array<String>:
            for (i, state) in adminDistricts.enumerated() {
                if statesByCity[state] == nil { // Avoid duplicates
                    statesByCity[state] = ["longitude": json["location"]["longitude"][i].int!, "latitude": json["location"]["latitude"][i].int!]
                }
            }
        case let adminDistrict as String:
            statesByCity[adminDistrict] = ["longitude": json["location"]["longitude"].int!, "latitude": json["location"]["latitude"].int!]
        default: print("was nil")
        }
        completion(statesByCity, nil)
    }
}

func getForecast(params: JSON, completion: @escaping (_ error: String?, _ forecast: JSON?) -> Void) {
    var p = params
    
    p["range"] = "7day"
    
    let fields = ["temp", "pop", "uv_index", "narrative", "phrase_12char", "phrase_22char", "phrase_32char"];
    
    guard let latitude = p["latitude"].double, let longitude = p["longitude"].double else {
        completion("Cannot be nil", nil)
        return
    }
    
    var qString: QueryString = [:]
    qString["units"] = "e"
    qString["language"] = "en-US"
    
    KituraRequest.request(.get, "https://twcservice.mybluemix.net/api/weather/v1/geocode/\(latitude)/\(longitude)/forecast/daily/7day.json", parameters: qString, headers: ["Authorization": "Basic ZWJiMDQyMmMtMTQ2Ny00YmQ2LTllNWItMWRhN2RlNzM0NzJmOnkxVUpXU01uSnA="]).response {
        request, response, data, error in
        if let error = error { print(error) }
        if response?.httpStatusCode.rawValue != 200 {
            completion("Error getting the forecast: HTTP Status \(String.init(describing: response?.httpStatusCode))", nil)
        } else {
            var forecastByDay: JSON = JSON([:])
            let json = JSON(data: data!)
            for(_, f) in json["forecasts"] {
                if !forecastByDay["dow"].exists() {
                    let dayFields = f["day"].filter( { return fields.contains($0.0) } ) // Convert these to non SwiftyJSON values
                    let nightFields = f["night"].filter( { return fields.contains($0.0) } )
                    // for each of the values we need to convert them to stringValue or intValue
                    let day = convert(json: dayFields)
                    let night = convert(json: nightFields)
                    if dayFields.count == 0 {
                        forecastByDay[f["dow"].stringValue] = ["night": night]
                    } else {
                        forecastByDay[f["dow"].stringValue] = ["day": day, "night": night]
                    }
                }
            }
            completion(nil, forecastByDay)
        }
    }
}

func convert(json: [JSONGenerator.Element]) -> [String:String] {
    var val: [String:String] = [:]
    for(key,fields) in json {
        val[key] = fields.stringValue
    }
    return val
}
