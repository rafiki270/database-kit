import Service

/// Configure the database connection pools.
public struct DatabaseConnectionPoolConfig: ServiceType {
    /// Maximum number of connections per pool.
    ///
    /// There will normally be multiple connection pools in your application,
    /// usually one per worker (where num workers = num logical CPU cores).
    ///
    /// The minimum supported value is `1`, meaning that your database must be able to handle
    /// at least n connections where n = num logical CPU cores.
    public var maxConnections: UInt

    /// Creates a new `DatabaseConnectionPoolConfig`
    public init(maxConnections: UInt) {
        assert(maxConnections >= 1) // minimum supported value is 1
        self.maxConnections = maxConnections
    }

    /// Creates a new `DatabaseConnectionPoolConfig` with default settings.
    public static func `default`() -> DatabaseConnectionPoolConfig {
        return .init(maxConnections: 2)
    }

    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> DatabaseConnectionPoolConfig {
        return .default()
    }
}
