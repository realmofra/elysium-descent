use starknet::ContractAddress;

// Global game counter for unique game IDs
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GameCounter {
    #[key]
    pub id: u32,
    pub count: u128,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub game_id: u128,
    pub player: ContractAddress,
    pub packed_adventurer: felt252,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct LootBox {
    #[key]
    pub game_id: u128,
    #[key]
    pub level: u32,
    #[key]
    pub box_id: u32,
    pub loot_type: u8,
    pub amount: u32,
    pub is_collected: bool,
    pub spawn_time: u64,
    pub expires_at: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct LootTable {
    #[key]
    pub level: u32,
    #[key]
    pub loot_type: u8,
    pub probability: u32,
    pub min_amount: u32,
    pub max_amount: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct LevelConfig {
    #[key]
    pub level: u32,
    pub max_loot_boxes: u32,
    pub spawn_interval: u64,
    pub box_lifetime: u64,
    pub gold_multiplier: u32,
}
