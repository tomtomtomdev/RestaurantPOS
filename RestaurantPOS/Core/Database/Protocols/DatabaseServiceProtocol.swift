//
//  DatabaseServiceProtocol.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import CoreData

/// Protocol defining the database service interface for Core Data operations
protocol DatabaseServiceProtocol {

    /// The main context for UI operations (main queue)
    var mainContext: NSManagedObjectContext { get }

    /// Creates a new background context for background operations
    func newBackgroundContext() -> NSManagedObjectContext

    /// Saves changes in the given context
    /// - Parameter context: The context to save
    /// - Throws: Core Data save errors
    func saveContext(_ context: NSManagedObjectContext) throws

    /// Performs a block on a background context and saves it
    /// - Parameter block: The block to execute with the background context
    /// - Throws: Core Data errors
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) throws
}
