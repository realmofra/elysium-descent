use dojo::world::WorldStorage;
use dojo::model::{ModelStorage};
use dojo::event::EventStorage;
use starknet::ContractAddress;

use super::super::models::game::{Game, LevelItems, GameCounter, GAME_COUNTER_ID};
use super::super::models::player::Player;
use super::super::models::inventory::PlayerInventory;
use super::super::models::world_state::WorldItem;
use super::super::types::game_types::GameStatus;
use super::super::types::item_types::ItemType;

use super::super::systems::actions::{GameCreated, LevelStarted, ItemPickedUp};

#[derive(Clone, Drop)]
pub struct Store {
    world: WorldStorage,
}

#[generate_trait]
pub impl StoreImpl of StoreTrait {
    fn new(world: WorldStorage) -> Store {
        Store { world }
    }

    fn world(self: @Store) -> WorldStorage {
        *self.world
    }

    // Game management methods
    fn create_game(ref self: Store, player: ContractAddress, timestamp: u64) -> u32 {
        // Get next game ID
        let mut counter: GameCounter = self.world.read_model(GAME_COUNTER_ID);
        if counter.next_game_id == 0 {
            let new_counter = GameCounter { counter_id: GAME_COUNTER_ID, next_game_id: 1 };
            self.world.write_model(@new_counter);
            counter = new_counter;
        }

        let game_id = counter.next_game_id;
        let updated_counter = GameCounter {
            counter_id: GAME_COUNTER_ID, next_game_id: counter.next_game_id + 1,
        };
        self.world.write_model(@updated_counter);

        // Create game
        let game = Game {
            game_id,
            player,
            status: GameStatus::InProgress,
            current_level: 0,
            created_at: timestamp,
            score: 0,
        };
        self.world.write_model(@game);

        // Initialize player
        let player_stats = Player {
            player, health: 100, max_health: 100, level: 1, experience: 0, items_collected: 0,
        };
        self.world.write_model(@player_stats);

        // Initialize inventory
        let inventory = PlayerInventory {
            player, health_potions: 0, survival_kits: 0, books: 0, capacity: 50,
        };
        self.world.write_model(@inventory);

        // Emit event
        self.world.emit_event(@GameCreated { player, game_id, created_at: timestamp });

        game_id
    }

    fn get_game(self: @Store, game_id: u32) -> Game {
        self.world.read_model(game_id)
    }

    fn update_game(ref self: Store, game: Game) {
        self.world.write_model(@game);
    }

    // Player management methods
    fn get_player(self: @Store, player: ContractAddress) -> Player {
        self.world.read_model(player)
    }

    fn update_player(ref self: Store, player: Player) {
        self.world.write_model(@player);
    }

    fn get_player_inventory(self: @Store, player: ContractAddress) -> PlayerInventory {
        self.world.read_model(player)
    }

    fn update_player_inventory(ref self: Store, inventory: PlayerInventory) {
        self.world.write_model(@inventory);
    }

    fn spawn_world_item(ref self: Store, item: WorldItem) {
        self.world.write_model(@item);
    }

    fn get_world_item(self: @Store, game_id: u32, item_id: u32) -> WorldItem {
        self.world.read_model((game_id, item_id))
    }

    fn update_world_item(ref self: Store, item: WorldItem) {
        self.world.write_model(@item);
    }

    fn get_level_items(self: @Store, game_id: u32, level: u32) -> LevelItems {
        self.world.read_model((game_id, level))
    }

    fn create_level_items(ref self: Store, level_items: LevelItems) {
        self.world.write_model(@level_items);
    }

    fn update_level_items(ref self: Store, level_items: LevelItems) {
        self.world.write_model(@level_items);
    }

    // Event helpers
    fn emit_level_started(
        ref self: Store, player: ContractAddress, game_id: u32, level: u32, items_spawned: u32,
    ) {
        self.world.emit_event(@LevelStarted { player, game_id, level, items_spawned });
    }

    fn emit_item_picked_up(
        ref self: Store,
        player: ContractAddress,
        game_id: u32,
        item_id: u32,
        item_type: ItemType,
        level: u32,
    ) {
        self.world.emit_event(@ItemPickedUp { player, game_id, item_id, item_type, level });
    }
}
