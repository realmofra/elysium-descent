pub use elysium_descent::models::index::{LootBox, LootTable};
use elysium_descent::types::loot::Loot;
use starknet::get_block_timestamp;

pub mod errors {}

#[generate_trait]
pub impl LootBoxImpl of LootBoxTrait {
    #[inline]
    fn new(game_id: u128, level: u32, box_id: u32, loot_type: Loot) -> LootBox {
        let current_time = get_block_timestamp();
        LootBox {
            game_id: game_id,
            level: level,
            box_id: box_id,
            loot_type: loot_type.into(),
            amount: 0,
            is_collected: false,
            spawn_time: current_time,
            // Expires 10 minutes after spawn
            expires_at: current_time + 600,
        }
    }
}

#[generate_trait]
pub impl LootTableImpl of LootTableTrait {
    #[inline]
    fn new(
        level: u32, loot_type: Loot, probability: u32, min_amount: u32, max_amount: u32,
    ) -> LootTable {
        LootTable {
            level: level,
            loot_type: loot_type.into(),
            probability: probability,
            min_amount: min_amount,
            max_amount: max_amount,
        }
    }
}
