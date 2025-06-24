use starknet::ContractAddress;
use elysium_descent::types::game_types::GameStatus;
use elysium_descent::types::item_types::ItemType;

/// Core game model containing game state, status, and metadata
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub game_id: u32,
    pub player: ContractAddress,
    pub status: GameStatus,
    pub current_level: u32,
    pub created_at: u64,
    pub score: u32,
}

/// Level-specific item tracking model for collection progress
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct LevelItems {
    #[key]
    pub game_id: u32,
    #[key]
    pub level: u32,
    pub total_health_potions: u32,
    pub total_survival_kits: u32,
    pub total_books: u32,
    pub collected_health_potions: u32,
    pub collected_survival_kits: u32,
    pub collected_books: u32,
}

/// Utility functions for querying item counts by type
#[generate_trait]
impl LevelItemsImpl of LevelItemsTrait {
    fn get_total_by_type(self: @LevelItems, item_type: ItemType) -> u32 {
        match item_type {
            ItemType::HealthPotion => *self.total_health_potions,
            ItemType::SurvivalKit => *self.total_survival_kits,
            ItemType::Book => *self.total_books,
        }
    }

    fn get_collected_by_type(self: @LevelItems, item_type: ItemType) -> u32 {
        match item_type {
            ItemType::HealthPotion => *self.collected_health_potions,
            ItemType::SurvivalKit => *self.collected_survival_kits,
            ItemType::Book => *self.collected_books,
        }
    }
}

/// Global counter model for generating unique sequential game IDs
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GameCounter {
    #[key]
    /// Always set to GAME_COUNTER_ID constant for singleton behavior
    pub counter_id: u32,
    pub next_game_id: u32,
}

/// Singleton identifier for the global game counter
pub const GAME_COUNTER_ID: u32 = 999999999;
