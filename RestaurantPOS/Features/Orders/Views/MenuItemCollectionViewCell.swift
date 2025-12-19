//
//  MenuItemCollectionViewCell.swift
//  RestaurantPOS
//
//  Created by Claude Code
//

import UIKit

// MARK: - Menu Item Collection View Cell

class MenuItemCollectionViewCell: UICollectionViewCell {
    static let identifier = "MenuItemCollectionViewCell"

    // MARK: - Properties

    private let containerView = UIView()
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let priceLabel = UILabel()
    private let preparationTimeLabel = UILabel()
    private let badgeStackView = UIStackView()
    private let addBadgeView = UIView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        setupContainer()
        setupImageView()
        setupLabels()
        setupBadges()
        setupConstraints()
    }

    private func setupContainer() {
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray5.cgColor
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.masksToBounds = false
    }

    private func setupImageView() {
        containerView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray3
    }

    private func setupLabels() {
        // Name label
        containerView.addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 2

        // Description label
        containerView.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2

        // Price label
        containerView.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        priceLabel.textColor = .systemGreen
        priceLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        priceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Preparation time label
        containerView.addSubview(preparationTimeLabel)
        preparationTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        preparationTimeLabel.font = UIFont.systemFont(ofSize: 12)
        preparationTimeLabel.textColor = .secondaryLabel
        preparationTimeLabel.textAlignment = .right
    }

    private func setupBadges() {
        // Add badge
        containerView.addSubview(addBadgeView)
        addBadgeView.translatesAutoresizingMaskIntoConstraints = false
        addBadgeView.backgroundColor = .systemBlue
        addBadgeView.layer.cornerRadius = 12
        addBadgeView.clipsToBounds = true

        let addLabel = UILabel()
        addLabel.translatesAutoresizingMaskIntoConstraints = false
        addLabel.text = "+"
        addLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        addLabel.textColor = .white
        addLabel.textAlignment = .center

        addBadgeView.addSubview(addLabel)
        NSLayoutConstraint.activate([
            addLabel.centerXAnchor.constraint(equalTo: addBadgeView.centerXAnchor),
            addLabel.centerYAnchor.constraint(equalTo: addBadgeView.centerYAnchor),
            addBadgeView.widthAnchor.constraint(equalToConstant: 24),
            addBadgeView.heightAnchor.constraint(equalToConstant: 24)
        ])

        // Badge stack for other badges
        containerView.addSubview(badgeStackView)
        badgeStackView.translatesAutoresizingMaskIntoConstraints = false
        badgeStackView.axis = .horizontal
        badgeStackView.spacing = 4
        badgeStackView.alignment = .center
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Image view
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            imageView.heightAnchor.constraint(equalToConstant: 120),

            // Name label
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: addBadgeView.leadingAnchor, constant: -8),

            // Add badge
            addBadgeView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            addBadgeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            addBadgeView.widthAnchor.constraint(equalToConstant: 24),
            addBadgeView.heightAnchor.constraint(equalToConstant: 24),

            // Description label
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Badge stack
            badgeStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            badgeStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),

            // Price label
            priceLabel.topAnchor.constraint(equalTo: badgeStackView.bottomAnchor, constant: 8),
            priceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            priceLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),

            // Preparation time label
            preparationTimeLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            preparationTimeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: priceLabel.trailingAnchor, constant: 8),
            preparationTimeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Configuration

    func configure(with item: MenuItem) {
        nameLabel.text = item.name
        descriptionLabel.text = item.description
        priceLabel.text = item.formattedPrice
        preparationTimeLabel.text = item.formattedPreparationTime

        // Load image if available
        if let imageURL = item.imageURL, !imageURL.isEmpty {
            // For now, use a placeholder image based on category
            configurePlaceholderImage(for: item)
        } else {
            configurePlaceholderImage(for: item)
        }

        setupBadges(for: item)
    }

    private func configurePlaceholderImage(for item: MenuItem) {
        // Use different system icons based on the item name or category
        let imageName: String
        let itemLower = item.name.lowercased()

        if itemLower.contains("burger") {
            imageName = "burger"
        } else if itemLower.contains("pizza") {
            imageName = "pizza"
        } else if itemLower.contains("drink") || itemLower.contains("cola") || itemLower.contains("tea") {
            imageName = "cup.and.saucer"
        } else if itemLower.contains("dessert") || itemLower.contains("brownie") || itemLower.contains("cheesecake") {
            imageName = "cake"
        } else if itemLower.contains("fries") {
            imageName = "fries"
        } else if itemLower.contains("wing") || itemLower.contains("stick") {
            imageName = "drumstick"
        } else {
            imageName = "fork.knife"
        }

        imageView.image = UIImage(systemName: imageName)
        imageView.backgroundColor = .systemGray6
        imageView.tintColor = .systemGray3
    }

    private func setupBadges(for item: MenuItem) {
        // Clear existing badges
        badgeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Popular badge (example logic)
        if item.name.contains("Classic") || item.name.contains("Cheeseburger") {
            addBadge(text: "Popular", color: .systemOrange)
        }

        // New badge (example logic)
        if item.name.contains("Margherita") {
            addBadge(text: "New", color: .systemGreen)
        }

        // Vegetarian badge (example based on ingredients)
        if item.ingredients.allSatisfy({ ingredient in
            ["Dough", "Tomato Sauce", "Mozzarella", "Basil", "Potatoes", "Sea Salt", "Tea", "Water", "Sugar"].contains(ingredient)
        }) {
            addBadge(text: "Veg", color: .systemMint)
        }

        // Quick prep badge
        if item.preparationTime < 180 { // Less than 3 minutes
            addBadge(text: "Quick", color: .systemBlue)
        }
    }

    private func addBadge(text: String, color: UIColor) {
        let badgeView = UIView()
        badgeView.backgroundColor = color
        badgeView.layer.cornerRadius = 8
        badgeView.clipsToBounds = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = .white

        badgeView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: badgeView.leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(lessThanOrEqualTo: badgeView.trailingAnchor, constant: -6),
            label.topAnchor.constraint(greaterThanOrEqualTo: badgeView.topAnchor, constant: 2),
            label.bottomAnchor.constraint(lessThanOrEqualTo: badgeView.bottomAnchor, constant: -2)
        ])

        badgeStackView.addArrangedSubview(badgeView)
    }

    // MARK: - Animation

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        descriptionLabel.text = nil
        priceLabel.text = nil
        preparationTimeLabel.text = nil
        imageView.image = nil
        badgeStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - Touch Handling

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                if self.isHighlighted {
                    self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                    self.containerView.alpha = 0.8
                } else {
                    self.containerView.transform = .identity
                    self.containerView.alpha = 1.0
                }
            }
        }
    }
}

// MARK: - Category Collection View Cell

class CategoryCollectionViewCell: UICollectionViewCell {
    static let identifier = "CategoryCollectionViewCell"

    // MARK: - Properties

    private let titleLabel = UILabel()
    private let categoryBackgroundView = UIView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        setupBackground()
        setupTitle()
        setupConstraints()
    }

    private func setupBackground() {
        contentView.addSubview(categoryBackgroundView)
        categoryBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        categoryBackgroundView.backgroundColor = .systemGray6
        categoryBackgroundView.layer.cornerRadius = 20
        categoryBackgroundView.layer.masksToBounds = true
    }

    private func setupTitle() {
        categoryBackgroundView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Background view
            categoryBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            categoryBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            categoryBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            categoryBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Title label
            titleLabel.centerXAnchor.constraint(equalTo: categoryBackgroundView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: categoryBackgroundView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: categoryBackgroundView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: categoryBackgroundView.trailingAnchor, constant: -12)
        ])
    }

    // MARK: - Configuration

    func configure(name: String, isSelected: Bool) {
        titleLabel.text = name

        if isSelected {
            categoryBackgroundView.backgroundColor = .systemBlue
            titleLabel.textColor = .white
        } else {
            categoryBackgroundView.backgroundColor = .systemGray6
            titleLabel.textColor = .label
        }
    }
}