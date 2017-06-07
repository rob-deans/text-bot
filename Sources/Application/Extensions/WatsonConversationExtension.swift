import Foundation
import ConversationV1
import CloudFoundryConfig

extension Conversation {

   public convenience init(service: WatsonConversationService) {

        let version = "2017-05-19"
            
        self.init(username: service.username, password: service.password, version: version)
        
    }
}
