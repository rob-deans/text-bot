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

//internal var couchDBClient: CouchDBClient?

internal var conversation: Conversation?

internal var nlu: NaturalLanguageUnderstanding?

internal var weather: Weather?
 
let failure = { (error: Swift.Error) in print("failure", error) }
 
internal var context: Context?

public func initialize() throws {

    manager.load(file: "config.json", relativeFrom: .project)
           .load(.environmentVariables)

    port = manager.port

    let sm = try SwiftMetrics()
    let _ = try SwiftMetricsDash(swiftMetricsInstance : sm, endpoint: router)

//    let cloudantService = try manager.getCloudantService(name: "Cloudant NoSQL DB-w8")
//    couchDBClient = CouchDBClient(service: cloudantService)
    
//    couchDBClient?.createDB("test") { _ , _ in }

    // Conversation
    let service = try manager.getWatsonConversationService(name: "Conversation-fg")
    conversation = Conversation(service: service, version: "2017-06-07")
    
    // NLU
    let NLUservice = try manager.getNaturalLanguageUnderstandingService(name: "Natural Language Understanding-0y")
    nlu = NaturalLanguageUnderstanding(service: NLUservice, version: "2017-06-07")
    
    // Weather
    let weatherService = try manager.getWeatherInsightService(name: "Weather Company Data-4c")
    weather = Weather(service: weatherService)
    
    initiliazeWatsonRoutes()
    
    router.all("/*", middleware: BodyParser())
    router.all("/", middleware: StaticFileServer())
}

public func run() throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}
