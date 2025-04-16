import Fluent

struct CreateEmailSettings: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("email_settings")
            .id()
            .field("imap_host", .string, .required)
            .field("imap_port", .int, .required)
            .field("imap_username", .string, .required)
            .field("imap_password", .string, .required)
            .field("smtp_host", .string, .required)
            .field("smtp_port", .int, .required)
            .field("smtp_username", .string, .required)
            .field("smtp_password", .string, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("email_settings").delete()
    }
} 