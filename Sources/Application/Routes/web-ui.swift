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
                            if json["city"][2]["number_of_states"].intValue == 1 {
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


typealias JSONDictionary = [String: Any?]
typealias QueryString = [String:Any]
typealias JSON = SwiftyJSON.JSON
typealias rkJSON = RestKit.JSON
