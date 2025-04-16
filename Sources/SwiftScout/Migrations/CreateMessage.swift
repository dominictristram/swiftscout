import Fluent

struct CreateMessage: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("messages")
            .id()
            .field("content", .string, .required)
            .field("ticket_id", .uuid, .required, .references("tickets", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("conversation_id", .uuid, .references("conversations", "id"))
            .field("created_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("messages").delete()
    }
} 