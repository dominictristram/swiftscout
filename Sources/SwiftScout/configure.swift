import Vapor
import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import JWT
import Leaf
import Redis
import Queues
import QueuesRedisDriver
import MailKit

func configure(_ app: Application) throws {
    // Configure Leaf
    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease
    
    // Configure database
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        let config = SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .disable
        )
        
        app.databases.use(.postgres(configuration: config), as: .psql)
    }
    
    // Configure Redis for queues
    app.redis.configuration = try RedisConfiguration(
        hostname: Environment.get("REDIS_HOST") ?? "localhost",
        port: Environment.get("REDIS_PORT").flatMap(Int.init(_:)) ?? 6379
    )
    
    // Configure JWT
    app.jwt.signers.use(.hs256(key: Environment.get("JWT_SECRET") ?? "secret"))
    
    // Configure migrations
    app.migrations.add([
        CreateUserTable(),
        CreateEmailSettings(),
        CreateTicket(),
        CreateConversation(),
        CreateMessage()
    ])
    
    // Run migrations
    try app.autoMigrate().wait()
    
    // Configure middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))
    
    // Configure routes
    try routes(app)
    
    // Configure content encoding/decoding
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    ContentConfiguration.global.use(decoder: decoder, for: .json)
}

private func ensurePostgreSQLIsRunning() async throws {
    // Add PostgreSQL health check here if needed
} 