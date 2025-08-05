//! Store struct and component management methods.

// Dojo imports
use dojo::world::WorldStorage;
use dojo::model::ModelStorage;

// Models imports
use elysium_descent::models::game_counter::GameCounter;
use elysium_descent::models::game::Game;
use elysium_descent::models::loot_box::{LootBox, LootTable};
use elysium_descent::models::config::LevelConfig;

// Structs
#[derive(Copy, Drop)]
pub struct Store {
    world: WorldStorage,
}

#[generate_trait]
pub impl StoreImpl of StoreTrait {
    #[inline]
    fn new(world: WorldStorage) -> Store {
        Store { world: world }
    }

    #[inline]
    fn set_game_counter(ref self: Store, count: GameCounter) {
        self.world.write_model(@count);
    }

    #[inline]
    fn get_game_counter(self: Store, id: u32) -> GameCounter {
        self.world.read_model(id)
    }

    #[inline]
    fn set_game(ref self: Store, game: Game) {
        self.world.write_model(@game);
    }

    #[inline]
    fn get_game(self: Store, id: u128) -> Game {
        self.world.read_model(id)
    }

    #[inline]
    fn set_loot_box(ref self: Store, loot_box: LootBox) {
        self.world.write_model(@loot_box);
    }

    #[inline]
    fn get_loot_box(self: Store, game_id: u128, level: u32, box_id: u32) -> LootBox {
        self.world.read_model((game_id, level, box_id))
    }

    #[inline]
    fn set_loot_table(ref self: Store, loot_table: LootTable) {
        self.world.write_model(@loot_table);
    }

    #[inline]
    fn get_loot_table(self: Store, level: u32, loot_type: u8) -> LootTable {
        self.world.read_model((level, loot_type))
    }

    #[inline]
    fn set_level_config(ref self: Store, level_config: LevelConfig) {
        self.world.write_model(@level_config);
    }

    #[inline]
    fn get_level_config(self: Store, level: u32) -> LevelConfig {
        self.world.read_model(level)
    }
}
