use starknet::ContractAddress;
use elysium_descent::types::item::ItemType;

/// Player inventory model for item storage and capacity management
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerInventory {
    #[key]
    pub player: ContractAddress,
    pub health_potions: u32,
    pub survival_kits: u32,
    pub books: u32,
    pub capacity: u32,
}

/// Inventory utility functions for item management operations
#[generate_trait]
impl PlayerInventoryImpl of PlayerInventoryTrait {
    fn get_item_count(self: @PlayerInventory, item_type: ItemType) -> u32 {
        match item_type {
            ItemType::HealthPotion => *self.health_potions,
            ItemType::SurvivalKit => *self.survival_kits,
            ItemType::Book => *self.books,
        }
    }

    fn add_item(ref self: PlayerInventory, item_type: ItemType, quantity: u32) {
        match item_type {
            ItemType::HealthPotion => self.health_potions += quantity,
            ItemType::SurvivalKit => self.survival_kits += quantity,
            ItemType::Book => self.books += quantity,
        }
    }

    fn remove_item(ref self: PlayerInventory, item_type: ItemType, quantity: u32) -> bool {
        match item_type {
            ItemType::HealthPotion => {
                if self.health_potions >= quantity {
                    self.health_potions -= quantity;
                    true
                } else {
                    false
                }
            },
            ItemType::SurvivalKit => {
                if self.survival_kits >= quantity {
                    self.survival_kits -= quantity;
                    true
                } else {
                    false
                }
            },
            ItemType::Book => {
                if self.books >= quantity {
                    self.books -= quantity;
                    true
                } else {
                    false
                }
            },
        }
    }
}
