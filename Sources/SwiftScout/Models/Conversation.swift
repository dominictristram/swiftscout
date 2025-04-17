import Vapor
import Fluent

enum ConversationStatus: String, Content {
    case active
    case closed
}

final class Conversation: Model, Content, Sendable {
    static let schema = "conversations"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "subject")
    var subject: String
    
    @Field(key: "status")
    var status: String
    
    @Parent(key: "user_id")
    var user: User
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, subject: String, status: String, userId: UUID) {
        self.id = id
        self.subject = subject
        self.status = status
        self.$user.id = userId
    }
}

enum ConversationType: String, Codable {
    case email
    case note
    case phone
    case chat
}

enum ConversationChannel: String, Codable {
    case email
    case web
    case phone
    case chat
    case api
}

extension Conversation {
    struct Create: Content {
        var ticketID: UUID
        var type: ConversationType
        var channel: ConversationChannel
        var status: ConversationStatus
    }
} 