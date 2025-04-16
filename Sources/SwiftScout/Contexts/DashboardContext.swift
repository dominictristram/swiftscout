import Vapor

struct DashboardContext: Content {
    let user: User
    let emailSettings: EmailSettings?
    let users: [User]?
} 