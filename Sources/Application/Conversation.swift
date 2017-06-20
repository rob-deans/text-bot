//
//  Conversation.swift
//  text-bot
//
//  Created by Robert Deans on 19/05/2017.
//
//

import Foundation
import SwiftyJSON
import ConversationV1


func sendMessageToConversation(_ message: JSON, context: Context?=nil, completion: @escaping (_ context: MessageResponse?, _ err: NSError?) -> Void) {
    let workspaceID = "3b6bb0fd-2f00-4e5e-9c9a-cbc74237b462"
    
    if let text = message["input"]["text"].string {
        var request: MessageRequest
        if let context = context {
            var ctx = context.json
            ctx["today"] = Day.today.description
            ctx["tomorrow"] = Day.tomorrow.description
            var c: Context? = nil
            do {
                c = try Context(json: rkJSON(dictionary: ctx))
            } catch let error {
                print(error)
            }
            request = MessageRequest(text: text, context: c)
        } else {
            request = MessageRequest(text: text)
        }
        conversation?.message(withWorkspace: workspaceID, request: request, failure: failure) { response in
            print(response.context.json)
            completion(response, nil)
        }
    } else {
        completion(nil, NSError(domain: "It did not work", code: 300))
    }
}

enum Day: CustomStringConvertible {
    
    case today
    case tomorrow
    
    var description: String {
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekdayOrdinal], from: date)
        
        let day = components.weekdayOrdinal!
        
        let Days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        
        switch self {
        case .today:
            return Days[day]
        case .tomorrow:
            return Days[day+1]
        }
    }
}
