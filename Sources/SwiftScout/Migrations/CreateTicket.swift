import Fluent

struct CreateTicket: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("tickets")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("status", .string, .required)
            .field("priority", .string, .required)
            .field("created_by_id", .uuid, .required, .references("users", "id"))
            .field("assigned_to_id", .uuid, .references("users", "id"))
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("tickets").delete()
    }
} 