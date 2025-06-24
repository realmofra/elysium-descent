// Item Categories - following Shinigami's hierarchical approach
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum ItemCategory {
    Consumable,
    Equipment,
    Material,
    Quest,
    Special,
}

// Basic Item Types for current implementation
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum ItemType {
    HealthPotion,
    SurvivalKit,
    Book,
}


// Item Rarity System
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub enum ItemRarity {
    Common,
    Uncommon,
    Rare,
    Epic,
    Legendary,
}

// Item Properties struct for detailed item data
#[derive(Clone, Drop, Serde, Introspect)]
pub struct ItemProperties {
    pub id: felt252,
    pub item_type: ItemType,
    pub rarity: ItemRarity,
    pub level_requirement: u32,
    pub stack_size: u32,
    pub value: u32,
    pub description: ByteArray,
    pub is_tradeable: bool,
    pub is_consumable: bool,
}

// Conversion traits
impl ItemTypeIntoFelt252 of Into<ItemType, felt252> {
    fn into(self: ItemType) -> felt252 {
        match self {
            ItemType::HealthPotion => 1,
            ItemType::SurvivalKit => 2,
            ItemType::Book => 3,
        }
    }
}

impl ItemCategoryIntoFelt252 of Into<ItemCategory, felt252> {
    fn into(self: ItemCategory) -> felt252 {
        match self {
            ItemCategory::Consumable => 1,
            ItemCategory::Equipment => 2,
            ItemCategory::Material => 3,
            ItemCategory::Quest => 4,
            ItemCategory::Special => 5,
        }
    }
}

impl ItemRarityIntoFelt252 of Into<ItemRarity, felt252> {
    fn into(self: ItemRarity) -> felt252 {
        match self {
            ItemRarity::Common => 1,
            ItemRarity::Uncommon => 2,
            ItemRarity::Rare => 3,
            ItemRarity::Epic => 4,
            ItemRarity::Legendary => 5,
        }
    }
}

// Type utility traits following Shinigami pattern
#[generate_trait]
pub impl ItemTypeImpl of ItemTypeTrait {
    fn get_category(self: @ItemType) -> ItemCategory {
        match self {
            ItemType::HealthPotion | ItemType::SurvivalKit => ItemCategory::Consumable,
            ItemType::Book => ItemCategory::Special,
        }
    }

    fn is_stackable(self: @ItemType) -> bool {
        match self {
            ItemType::HealthPotion | ItemType::SurvivalKit => true,
            ItemType::Book => false,
        }
    }

    fn get_max_stack_size(self: @ItemType) -> u32 {
        match self {
            ItemType::HealthPotion => 99,
            ItemType::SurvivalKit => 10,
            ItemType::Book => 1,
        }
    }

    fn is_consumable(self: @ItemType) -> bool {
        match self {
            ItemType::HealthPotion | ItemType::SurvivalKit | ItemType::Book => true,
        }
    }
}
