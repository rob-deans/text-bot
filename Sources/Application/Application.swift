import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudFoundryConfig
import SwiftMetrics
import SwiftMetricsDash
import CouchDB
import ConversationV1
import NaturalLanguageUnderstandingV1

public let router = Router()
public let manager = ConfigurationManager()
public var port: Int = 8080

internal var couchDBClient: CouchDBClient?

//var username: String?
//var password: String?

internal var conversation: Conversation?

internal var nlu: NaturalLanguageUnderstanding?
 
let failure = { (error: Swift.Error) in print("failure", error) }
 
internal var context: Context?

public func initialize() throws {

    manager.load(file: "config.json", relativeFrom: .project)
           .load(.environmentVariables)

    port = manager.port

    let sm = try SwiftMetrics()
    let _ = try SwiftMetricsDash(swiftMetricsInstance : sm, endpoint: router)

    let cloudantService = try manager.getCloudantService(name: "text-bot-Cloudant-d0c5")
    couchDBClient = CouchDBClient(service: cloudantService)
    
    couchDBClient?.createDB("test") { _ , _ in }

    // Conversation
    let service = try manager.getWatsonConversationService(name: "text-bot-WatsonConversation-j9b3")
    conversation = Conversation(service: service)
    
    // NLU
    // Natural langauge understanding
    // TODO: Add this to cloud configuration
    let username = "430f4dc1-4108-42ab-8a8e-e8aeb53b97ae"
    let password = "JFLFIaFTyeid"
    let version = "2017-05-19" // use today's date for the most recent version
    nlu = NaturalLanguageUnderstanding(username: username, password: password, version: version)
    
    initiliazeWatsonRoutes()
    
    router.all("/*", middleware: BodyParser())
    router.all("/", middleware: StaticFileServer())
}

public func run() throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}
