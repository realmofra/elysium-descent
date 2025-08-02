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
struct LootBox {
    #[key]
    game_id: u128,
    #[key]
    level: u32,
    #[key]
    box_id: u32,
    loot_type: u8,
    amount: u32,
    is_collected: bool,
    spawn_time: u64,
    expires_at: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct LootTable {
    #[key]
    level: u32,
    #[key]
    loot_type: u8,
    probability: u32,
    min_amount: u32,
    max_amount: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct LevelConfig {
    #[key]
    level: u32,
    max_loot_boxes: u32,
    spawn_interval: u64,
    box_lifetime: u64,
    gold_multiplier: u32,
}
