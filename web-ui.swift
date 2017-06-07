//
//  web-ui.swift
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

func initiliazeWatsonRoutes() {
    
    // Routers
    
    router.all("/api", middleware: BodyParser())
    
    router.post("/api/message") { req, res, next in
        guard let parsedBody = req.body else {
            next()
            return
        }
        switch parsedBody {
        case .json(let jsonBody):
            processMessage(jsonBody) { err, response in
                if let err = err {
                    res.send(json: [ "error": err.domain ])
                } else {
                    res.send(json: response!.json)
                }
                next()
            }
        default: break
        }
    }
}

func processMessage(_ _message: JSON, completion: @escaping (_ err: NSError?, _ response: MessageResponse?) -> Void) {

    var message = _message
    if let text = _message["text"].string {
        message["input"] = ["text": text]
    }
    let input = message["input"]
//    guard let _ = message["name"].string else {
//        completion(NSError(domain: "Something went wrong with getting the user", code: 400), nil)
//        return
//    }
    
//    getUser(user) { err, person in
//        if let err = err { print(err) }
        extractCity(text: input) { city in
            if let c = city {
                // Add the city to the context
                print("extracted city", c)
                var ctx = context?.json
                ctx?["city"]  = ["name": c, "alternate_name": c]
                do {
                    context = try Context(json: RestKit.JSON(dictionary: ctx!))
                } catch let error {
                    print(error)
                }
                if context!.json["city"] != nil && context!.json["state"] == nil {
                    getGeoLocation(city: c) { geoLocatedCity, err in
                        if let err = err { completion(err as NSError, nil) }
                        if let geoLocatedCity = geoLocatedCity {
                            var ctx = context!.json
                            var json = JSON(ctx)
                            json["city"] = ["name": c, "alternate_name": c, "states": geoLocatedCity, "number_of_states": JSON(geoLocatedCity as Any).count]
//                            json["city"] = ["name": c, ]
                            if json["city"]["number_of_states"].intValue == 1 {
                                ctx["state"] = json["city"]["states"][0]
                            }
                            do {
                                context = try Context(json: RestKit.JSON(dictionary: json.dictionaryObject!))
                            } catch let error {
                                print(error)
                            }
                        }
                    }
                }
            }
            sendMessageToConversation(message, context: context) { response, error in
                context = response!.context

                let responseContext = response!.context
                if responseContext.json["new_city"] != nil { // new query
                    var json = JSON(responseContext.json)
                    
                    json["weather_conditions"] = nil
                    json["state"] = nil
                    json["get_weather"] = nil
                    json["new_city"] = nil
                    let city = json["city"][0]
                    getGeoLocation(city: city.string!) { geoLocatedCity, err in
                        if let geoLocatedCity = geoLocatedCity {
                            var ctx = context!.json
                            var json = JSON(ctx)
                            let city = json["city"][0]
                            json["city"] = ["name": city, "alternate_name": city, "states": geoLocatedCity, "number_of_states": JSON(geoLocatedCity as Any).count]
                            if json["city"][2]["number_of_states"].int! == 1 {
                                ctx["state"] = json["city"]["states"][0]
                            }
                            do {
                                context = try Context(json: RestKit.JSON(dictionary: json.dictionaryObject!))
                            } catch let error {
                                print(error)
                            }
                            let message = ["input": response!.input!.json, "context": context!] as [String : Any]
                            sendMessageToConversation(JSON(message)) { response, err in
                                if let err = err {
                                    print(err)
                                }
                                if let response = response {
                                    context = response.context
                                }
                            }
                        }
                    }
                }
                
                var json = JSON(response!.context.json)
                
                if let get_weather = json["get_weather"].bool {
                    if !get_weather {
                        completion(nil, response)
                        return
                    }
                }
                
                // BEGIN update context for get_weather
                if json["city"]["name"] != nil && json["state"] != nil {
                    let loc = JSON(["city": json["city"]["name"].string, "state": json["state"].string])
                    if let state = loc["state"].string {
                        let gLocation = json["city"]["states"][state]
                        if gLocation == nil {
                            json["input"] = "Hello"
                            sendMessageToConversation(json) { response, error in
                                if let error = error {
                                    completion(error, nil)
                                }
                                completion(nil, response)
                            }
                        }
                        json["city"]["number_of_states"] = 1
                        json["get_weather"] = nil
                        // END update context for get_weather
                        
                        getForecast(params: gLocation) { error, forecast in
                            if let error = error {
                                print(error)
                            }
                            if let forecast = forecast {
                                var ctx = context!.json
                                ctx["weather_conditions"] = forecast.dictionaryObject!
                                do {
                                    context = try Context(json: rkJSON(dictionary: ctx))
                                } catch let error {
                                    print(error)
                                }
                                sendMessageToConversation(message, context: context) { response, error in
                                    if let error = error {
                                        completion(error, nil)
                                    } else {
                                        completion(nil, response)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    sendMessageToConversation(message, context: context) { response, error in
                        if let error = error {
                            completion(error, nil)
                        } else {
                            completion(nil, response)
                        }
                    }
                }
            }
        }
//    }
}

func getUser(_ user: String, completion: @escaping (_ error: NSError?, _ response: JSON?) -> Void) {
    let userDatabase = couchDBClient?.usersDatabase()
    userDatabase?.getUser(name: user) { data , err in
     completion(err, data)
    }
}

func putUser(_ user: String, completion: @escaping (_ id: String?, _ doc: JSON?, _ err: Swift.Error?) -> Void) {
    let userDatabase = couchDBClient?.usersDatabase()
    var newUser = JSONDictionary()
    newUser["type"]        	= user
    newUser["roles"]       	= []
    
    let document = JSON(newUser)
    userDatabase?.createUser(document: document) { id, doc, error in
       completion(id, doc, error)
    }
}

func extractCity(text params: JSON, completion: @escaping (_ success: String?) -> Void) {
    // Alchemy lang
    let features = Features(entities: EntitiesOptions(limit: 1))
    let parameters  = Parameters(features: features, text: params["text"].string, language: "en")
    
    func isCity(_ entity: EntitiesResult) -> Bool {
        return entity.type! == "Location"
    }
    
    func onlyName(_ city: EntitiesResult) -> String {
        return city.text!
    }
    
    nlu?.analyzeContent(withParameters: parameters, failure: failure) { success in
        var city = success.entities?.filter(isCity).map(onlyName)
        completion((city?.count)! > 0 ? city?[0] : nil)
    }
}

// Weather
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

typealias JSONDictionary = [String: Any?]
typealias QueryString = [String:Any]
typealias JSON = SwiftyJSON.JSON
typealias rkJSON = RestKit.JSON
