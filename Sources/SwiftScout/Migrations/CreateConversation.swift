import Fluent

struct CreateConversation: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("conversations")
            .id()
            .field("ticket_id", .uuid, .required, .references("tickets", "id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("conversations").delete()
    }
} 