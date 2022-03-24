import Fluent
import FluentPostgresDriver
import Vapor
import telegram_vapor_bot

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 80
    
    let tgApi: String = "5110668200:AAG8CqcfPz4tMs700J6cmdZyVhw9qPUkDTQ"
    let connection: TGConnectionPrtcl = TGLongPollingConnection()
    TGBot.configure(connection: connection, botId: tgApi, vaporClient: app.client)
    try TGBot.shared.start()
    TGBot.log.logLevel = .error
    DefaultBotHandlers.share.addHandlers(app: app, bot: TGBot.shared)
    
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)
    
    app.migrations.add(CreateTodo())
    
    try routes(app)
}
