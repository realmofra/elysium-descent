use starknet::ContractAddress;
use super::super::types::game_types::GameStatus;
use super::super::types::item_types::ItemType;

// Simplified game instance for current implementation
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

// Level items spawned per level
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

// Global game counter for unique game IDs
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GameCounter {
    #[key]
    pub counter_id: u32, // Use constant GAME_COUNTER_ID
    pub next_game_id: u32,
}

// Constants for special identifiers
pub const GAME_COUNTER_ID: u32 = 999999999;




