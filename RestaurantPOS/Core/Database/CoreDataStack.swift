//
//  CoreDataStack.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import CoreData

/// Core Data stack manager for the RestaurantPOS application
public final class CoreDataStack: DatabaseServiceProtocol {

    // MARK: - Properties

    /// Shared singleton instance
    public static let shared = CoreDataStack()

    /// The persistent container
    private let persistentContainer: NSPersistentContainer

    /// Main context for UI operations (main queue)
    public var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Initialization

    /// Initializes the Core Data stack with a given model name
    /// - Parameter modelName: The name of the Core Data model (default: "RestaurantPOS")
    public init(modelName: String = "RestaurantPOS") {
        persistentContainer = NSPersistentContainer(name: modelName)
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error.localizedDescription)")
            }
        }

        // Configure the view context
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Initializes an in-memory Core Data stack for testing
    /// - Parameter inMemory: Whether to use in-memory storage
    public init(inMemory: Bool) {
        persistentContainer = NSPersistentContainer(name: "RestaurantPOS")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            persistentContainer.persistentStoreDescriptions = [description]
        }

        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error.localizedDescription)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - DatabaseServiceProtocol Methods

    /// Creates a new background context for background operations
    /// - Returns: A new background managed object context
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Saves changes in the given context
    /// - Parameter context: The context to save
    /// - Throws: Core Data save errors
    public func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            // Log the error or handle it appropriately
            throw error
        }
    }

    /// Performs a block on a background context and saves it
    /// - Parameter block: The block to execute with the background context
    /// - Throws: Core Data errors
    public func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) throws {
        let context = newBackgroundContext()

        var blockError: Error?

        context.performAndWait {
            do {
                try block(context)
                try saveContext(context)
            } catch {
                blockError = error
            }
        }

        if let error = blockError {
            throw error
        }
    }

    // MARK: - Utility Methods

    /// Deletes all data from the persistent store (useful for testing)
    func deleteAllData() throws {
        let entities = persistentContainer.managedObjectModel.entities

        for entity in entities {
            guard let entityName = entity.name else { continue }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try persistentContainer.viewContext.execute(deleteRequest)
                try saveContext(persistentContainer.viewContext)
            } catch {
                throw error
            }
        }
    }
}
