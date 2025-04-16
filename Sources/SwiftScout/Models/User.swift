import Fluent
import Vapor
import JWT

final class User: Model, Authenticatable, AsyncResponseEncodable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Enum(key: "role")
    var role: Role
    
    @Field(key: "is_suspended")
    var isSuspended: Bool
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil, name: String, email: String, passwordHash: String, role: Role, isSuspended: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
        self.isSuspended = isSuspended
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
    
    func toPublic() -> Public {
        Public(id: id, name: name, email: email, role: role, isSuspended: isSuspended)
    }
    
    func encodeResponse(for request: Request) async throws -> Response {
        try await toPublic().encodeResponse(for: request)
    }
}

extension User {
    enum Role: String, Codable {
        case admin
        case agent
        case customer
    }
    
    struct Public: Content {
        let id: UUID?
        let name: String
        let email: String
        let role: Role
        let isSuspended: Bool
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
}

extension User {
    struct Create: Content {
        var email: String
        var password: String
        var name: String
        var role: Role
    }
    
    func generateToken(_ app: Application) throws -> String {
        let payload = UserPayload(
            subject: SubjectClaim(value: email),
            expiration: ExpirationClaim(value: Date().addingTimeInterval(3600)),
            userID: try requireID(),
            email: email,
            role: role
        )
        return try app.jwt.signers.sign(payload)
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
        validations.add("name", as: String.self, is: .count(1...))
    }
} 