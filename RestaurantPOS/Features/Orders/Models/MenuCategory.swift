import Foundation

public struct MenuCategory: Identifiable, Codable, Equatable {
    public let id: UUID
    public let name: String
    public let description: String?
    public let imageURL: String?
    public let sortOrder: Int
    public let isActive: Bool
    public let subcategories: [UUID]

    public init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        imageURL: String? = nil,
        sortOrder: Int = 0,
        isActive: Bool = true,
        subcategories: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.imageURL = imageURL
        self.sortOrder = sortOrder
        self.isActive = isActive
        self.subcategories = subcategories
    }
}

// MARK: - Helper Extensions

extension MenuCategory {
    public var hasSubcategories: Bool {
        !subcategories.isEmpty
    }

    public var hasImage: Bool {
        imageURL != nil && !imageURL!.isEmpty
    }
}

// MARK: - Sample Data

extension MenuCategory {
    public static let sampleCategories: [MenuCategory] = [
        MenuCategory(
            name: "Burgers",
            description: "Our signature burger collection",
            sortOrder: 1,
            subcategories: []
        ),
        MenuCategory(
            name: "Pizzas",
            description: "Wood-fired pizzas with fresh ingredients",
            sortOrder: 2,
            subcategories: []
        ),
        MenuCategory(
            name: "Beverages",
            description: "Soft drinks, coffee, and more",
            sortOrder: 3,
            subcategories: []
        ),
        MenuCategory(
            name: "Desserts",
            description: "Sweet treats to finish your meal",
            sortOrder: 4,
            subcategories: []
        ),
        MenuCategory(
            name: "Sides",
            description: "Perfect accompaniments for your meal",
            sortOrder: 5,
            subcategories: []
        ),
        MenuCategory(
            name: "Appetizers",
            description: "Start your meal with something delicious",
            sortOrder: 6,
            subcategories: []
        )
    ]
}

extension MenuItem {
    public static let sampleItems: [MenuItem] = [
        // Burgers
        MenuItem(
            name: "Classic Burger",
            description: "Beef patty with lettuce, tomato, onion, pickles, and our special sauce",
            price: 12.99,
            categoryID: MenuCategory.sampleCategories[0].id,
            imageURL: nil,
            preparationTime: 300,
            ingredients: ["Beef", "Bun", "Lettuce", "Tomato", "Onion", "Pickles"],
            allergens: ["Gluten", "Soy"],
            modifiers: [
                MenuItemModifier(name: "Extra Cheese", price: 1.50),
                MenuItemModifier(name: "Bacon", price: 2.00),
                MenuItemModifier(name: "Avocado", price: 1.75)
            ]
        ),
        MenuItem(
            name: "Cheeseburger",
            description: "Classic burger with American cheese",
            price: 13.49,
            categoryID: MenuCategory.sampleCategories[0].id,
            preparationTime: 300,
            ingredients: ["Beef", "Bun", "Lettuce", "Tomato", "Cheese", "Onion", "Pickles"],
            allergens: ["Gluten", "Soy", "Dairy"],
            modifiers: [
                MenuItemModifier(name: "Extra Cheese", price: 1.50),
                MenuItemModifier(name: "Bacon", price: 2.00)
            ]
        ),

        // Pizzas
        MenuItem(
            name: "Margherita Pizza",
            description: "Fresh mozzarella, tomato sauce, and basil",
            price: 14.99,
            categoryID: MenuCategory.sampleCategories[1].id,
            preparationTime: 600,
            ingredients: ["Dough", "Tomato Sauce", "Mozzarella", "Basil"],
            allergens: ["Gluten", "Dairy"],
            modifiers: [
                MenuItemModifier(name: "Extra Cheese", price: 2.50),
                MenuItemModifier(name: "Pepperoni", price: 3.00)
            ]
        ),
        MenuItem(
            name: "Pepperoni Pizza",
            description: "Classic pepperoni with mozzarella",
            price: 16.99,
            categoryID: MenuCategory.sampleCategories[1].id,
            preparationTime: 600,
            ingredients: ["Dough", "Tomato Sauce", "Mozzarella", "Pepperoni"],
            allergens: ["Gluten", "Dairy", "Pork"],
            modifiers: [
                MenuItemModifier(name: "Extra Cheese", price: 2.50),
                MenuItemModifier(name: "Mushrooms", price: 2.00)
            ]
        ),

        // Beverages
        MenuItem(
            name: "Coca Cola",
            description: "Classic Coca-Cola",
            price: 2.99,
            categoryID: MenuCategory.sampleCategories[2].id,
            preparationTime: 30,
            ingredients: ["Carbonated Water", "Sugar", "Caffeine", "Natural Flavors"],
            allergens: []
        ),
        MenuItem(
            name: "Iced Tea",
            description: "Fresh brewed iced tea",
            price: 2.49,
            categoryID: MenuCategory.sampleCategories[2].id,
            preparationTime: 60,
            ingredients: ["Tea", "Water", "Sugar"],
            allergens: []
        ),

        // Sides
        MenuItem(
            name: "French Fries",
            description: "Crispy golden french fries with sea salt",
            price: 4.99,
            categoryID: MenuCategory.sampleCategories[4].id,
            preparationTime: 240,
            ingredients: ["Potatoes", "Sea Salt", "Vegetable Oil"],
            allergens: []
        ),
        MenuItem(
            name: "Onion Rings",
            description: "Crispy beer-battered onion rings",
            price: 5.99,
            categoryID: MenuCategory.sampleCategories[4].id,
            preparationTime: 300,
            ingredients: ["Onions", "Flour", "Beer", "Vegetable Oil"],
            allergens: ["Gluten", "Alcohol"]
        ),

        // Desserts
        MenuItem(
            name: "Chocolate Brownie",
            description: "Warm chocolate brownie with vanilla ice cream",
            price: 6.99,
            categoryID: MenuCategory.sampleCategories[3].id,
            preparationTime: 120,
            ingredients: ["Chocolate", "Flour", "Sugar", "Eggs", "Butter", "Vanilla Ice Cream"],
            allergens: ["Gluten", "Eggs", "Dairy", "Soy", "Nuts"]
        ),
        MenuItem(
            name: "Cheesecake",
            description: "New York style cheesecake with berry compote",
            price: 7.99,
            categoryID: MenuCategory.sampleCategories[3].id,
            preparationTime: 180,
            ingredients: ["Cream Cheese", "Sugar", "Eggs", "Vanilla", "Graham Crackers"],
            allergens: ["Gluten", "Eggs", "Dairy"]
        ),

        // Appetizers
        MenuItem(
            name: "Chicken Wings",
            description: "Crispy chicken wings with your choice of sauce",
            price: 9.99,
            categoryID: MenuCategory.sampleCategories[5].id,
            preparationTime: 420,
            ingredients: ["Chicken", "Flour", "Spices", "Vegetable Oil"],
            allergens: ["Gluten"],
            modifiers: [
                MenuItemModifier(name: "Buffalo Sauce", price: 0.00),
                MenuItemModifier(name: "BBQ Sauce", price: 0.00),
                MenuItemModifier(name: "Honey Mustard", price: 0.00)
            ]
        ),
        MenuItem(
            name: "Mozzarella Sticks",
            description: "Breaded mozzarella sticks with marinara sauce",
            price: 7.99,
            categoryID: MenuCategory.sampleCategories[5].id,
            preparationTime: 360,
            ingredients: ["Mozzarella", "Breadcrumbs", "Eggs", "Flour", "Marinara Sauce"],
            allergens: ["Gluten", "Dairy", "Eggs"]
        )
    ]
}