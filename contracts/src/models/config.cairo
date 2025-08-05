pub use elysium_descent::models::index::{LevelConfig};

pub mod errors {}

#[generate_trait]
pub impl LevelConfigImpl of LevelConfigTrait {
    #[inline]
    fn new(level: u32, max_loot_boxes: u32) -> LevelConfig {
        LevelConfig {
            level: level,
            max_loot_boxes: max_loot_boxes,
            spawn_interval: 100,
            box_lifetime: 600,
            gold_multiplier: 0,
        }
    }
}
