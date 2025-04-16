import Fluent

struct AddIsSuspendedToUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .field("is_suspended", .bool, .required, .sql(.default(false)))
            .update()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("users")
            .deleteField("is_suspended")
            .update()
    }
} 