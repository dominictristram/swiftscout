import Fluent
import Vapor

final class EmailSettings: Model, Content, Sendable {
    static let schema = "email_settings"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "imap_host")
    var imapHost: String
    
    @Field(key: "imap_port")
    var imapPort: Int
    
    @Field(key: "imap_username")
    var imapUsername: String
    
    @Field(key: "imap_password")
    var imapPassword: String
    
    @Field(key: "smtp_host")
    var smtpHost: String
    
    @Field(key: "smtp_port")
    var smtpPort: Int
    
    @Field(key: "smtp_username")
    var smtpUsername: String
    
    @Field(key: "smtp_password")
    var smtpPassword: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, imapHost: String, imapPort: Int, imapUsername: String, imapPassword: String,
         smtpHost: String, smtpPort: Int, smtpUsername: String, smtpPassword: String) {
        self.id = id
        self.imapHost = imapHost
        self.imapPort = imapPort
        self.imapUsername = imapUsername
        self.imapPassword = imapPassword
        self.smtpHost = smtpHost
        self.smtpPort = smtpPort
        self.smtpUsername = smtpUsername
        self.smtpPassword = smtpPassword
    }
} 