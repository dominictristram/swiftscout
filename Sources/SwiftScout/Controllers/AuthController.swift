@preconcurrency import JWT
import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        // Routes are configured in routes.swift
    }
    
    func register(req: Request) async throws -> TokenResponse {
        do {
            try User.Create.validate(content: req)
            let create = try req.content.decode(User.Create.self)
            
            guard try await User.query(on: req.db)
                .filter(\.$email == create.email)
                .first() == nil else {
                throw Abort(.conflict, reason: "A user with this email already exists")
            }
            
            let user = try User(
                id: nil,
                email: create.email,
                passwordHash: try Bcrypt.hash(create.password),
                name: create.name,
                role: create.role,
                isSuspended: false
            )
            
            try await user.save(on: req.db)
            
            let payload = UserPayload(
                subject: .init(value: user.email),
                expiration: .init(value: Date().addingTimeInterval(3600)),
                userID: try user.requireID(),
                email: user.email,
                role: user.role
            )
            
            let token = try req.jwt.sign(payload)
            return TokenResponse(token: token)
        } catch {
            req.logger.error("Registration error: \(String(reflecting: error))")
            throw error
        }
    }
    
    func login(req: Request) async throws -> TokenResponse {
        let credentials = try req.content.decode(LoginRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == credentials.email)
            .first() else {
            throw Abort(.unauthorized)
        }
        
        guard try Bcrypt.verify(credentials.password, created: user.passwordHash) else {
            throw Abort(.unauthorized)
        }
        
        let payload = UserPayload(
            subject: .init(value: user.email),
            expiration: .init(value: Date().addingTimeInterval(3600)),
            userID: user.id!,
            email: user.email,
            role: user.role
        )
        
        let token = try req.jwt.sign(payload)
        return TokenResponse(token: token)
    }
}

struct LoginRequest: Content {
    let email: String
    let password: String
}

struct TokenResponse: Content {
    let token: String
}

struct UserPayload: JWTPayload, Sendable {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case userID = "user_id"
        case email
        case role
    }
    
    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var userID: UUID
    var email: String
    var role: UserRole
    
    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
} 