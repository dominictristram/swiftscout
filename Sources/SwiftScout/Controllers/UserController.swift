import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.get(use: index)
        users.post(use: create)
        users.get("me", use: getCurrentUser)
        users.group(":userID") { user in
            user.get(use: show)
            user.put(use: update)
            user.delete(use: delete)
            user.put("reset-password", use: resetPassword)
            user.put("suspend", use: suspend)
        }
    }
    
    func index(req: Request) async throws -> [User.Public] {
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.forbidden, reason: "Only admins can list users")
        }
        return try await User.query(on: req.db).all().map { $0.toPublic() }
    }
    
    func create(req: Request) async throws -> User.Public {
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.forbidden, reason: "Only admins can create users")
        }
        let create = try req.content.decode(CreateUserRequest.self)
        let newUser = User(
            name: create.name,
            email: create.email,
            passwordHash: try Bcrypt.hash(create.password),
            role: create.role
        )
        try await newUser.save(on: req.db)
        return newUser.toPublic()
    }
    
    func getCurrentUser(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        return user.toPublic()
    }
    
    func show(req: Request) async throws -> User.Public {
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.forbidden, reason: "Only admins can view user details")
        }
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        return user.toPublic()
    }
    
    func update(req: Request) async throws -> User.Public {
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.forbidden, reason: "Only admins can update users")
        }
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        let update = try req.content.decode(UpdateUserRequest.self)
        user.name = update.name
        try await user.save(on: req.db)
        return user.toPublic()
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.forbidden, reason: "Only admins can delete users")
        }
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        try await user.delete(on: req.db)
        return .noContent
    }
    
    func resetPassword(req: Request) async throws -> HTTPStatus {
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.forbidden, reason: "Only admins can reset passwords")
        }
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        let reset = try req.content.decode(ResetPasswordRequest.self)
        user.passwordHash = try Bcrypt.hash(reset.password)
        try await user.save(on: req.db)
        return .ok
    }
    
    func suspend(req: Request) async throws -> HTTPStatus {
        guard let user = req.auth.get(User.self), user.role == .admin else {
            throw Abort(.forbidden, reason: "Only admins can suspend users")
        }
        guard let userID = req.parameters.get("userID", as: UUID.self),
              let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound)
        }
        user.isSuspended = true
        try await user.save(on: req.db)
        return .ok
    }
}

struct CreateUserRequest: Content {
    let name: String
    let email: String
    let password: String
    let role: User.Role
}

struct UpdateUserRequest: Content {
    let name: String
}

struct ResetPasswordRequest: Content {
    let password: String
} 