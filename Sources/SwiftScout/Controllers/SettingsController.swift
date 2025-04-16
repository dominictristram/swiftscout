import Vapor
import Fluent

struct SettingsController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let settings = routes.grouped("settings")
        settings.get("email", use: getEmailSettings)
        settings.post("email", use: updateEmailSettings)
    }
    
    func getEmailSettings(req: Request) async throws -> EmailSettings {
        // Get the first (and only) email settings record
        if let settings = try await EmailSettings.query(on: req.db).first() {
            return settings
        }
        
        // If no settings exist, create default ones
        let defaultSettings = EmailSettings(
            imapHost: "imap.example.com",
            imapPort: 993,
            imapUsername: "",
            imapPassword: "",
            smtpHost: "smtp.example.com",
            smtpPort: 587,
            smtpUsername: "",
            smtpPassword: ""
        )
        try await defaultSettings.save(on: req.db)
        return defaultSettings
    }
    
    func updateEmailSettings(req: Request) async throws -> HTTPStatus {
        let newSettings = try req.content.decode(EmailSettingsRequest.self)
        
        // Get existing settings or create new ones
        if let existingSettings = try await EmailSettings.query(on: req.db).first() {
            existingSettings.imapHost = newSettings.imapHost
            existingSettings.imapPort = newSettings.imapPort
            existingSettings.imapUsername = newSettings.imapUsername
            existingSettings.imapPassword = newSettings.imapPassword
            existingSettings.smtpHost = newSettings.smtpHost
            existingSettings.smtpPort = newSettings.smtpPort
            existingSettings.smtpUsername = newSettings.smtpUsername
            existingSettings.smtpPassword = newSettings.smtpPassword
            try await existingSettings.save(on: req.db)
        } else {
            let settings = EmailSettings(
                imapHost: newSettings.imapHost,
                imapPort: newSettings.imapPort,
                imapUsername: newSettings.imapUsername,
                imapPassword: newSettings.imapPassword,
                smtpHost: newSettings.smtpHost,
                smtpPort: newSettings.smtpPort,
                smtpUsername: newSettings.smtpUsername,
                smtpPassword: newSettings.smtpPassword
            )
            try await settings.save(on: req.db)
        }
        
        return .ok
    }
}

struct EmailSettingsRequest: Content {
    let imapHost: String
    let imapPort: Int
    let imapUsername: String
    let imapPassword: String
    let smtpHost: String
    let smtpPort: Int
    let smtpUsername: String
    let smtpPassword: String
} 