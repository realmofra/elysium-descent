use dojo::world::WorldStorage;
use dojo::model::{ModelStorage};
use dojo::event::EventStorage;
use starknet::ContractAddress;

use elysium_descent::models::game::{Game, LevelItems, GameCounter, GAME_COUNTER_ID};
use elysium_descent::models::player::Player;
use elysium_descent::models::inventory::PlayerInventory;
use elysium_descent::models::world_state::WorldItem;
use elysium_descent::types::item::ItemType;

use elysium_descent::systems::actions::{GameCreated, LevelStarted, ItemPickedUp};

#[derive(Clone, Drop)]
pub struct Store {
    world: WorldStorage,
}

#[generate_trait]
pub impl StoreImpl of StoreTrait {
    fn new(world: WorldStorage) -> Store {
        Store { world }
    }

    /// Game counter management
    fn get_game_counter(self: @Store) -> GameCounter {
        self.world.read_model(GAME_COUNTER_ID)
    }

    fn set_game_counter(ref self: Store, counter: GameCounter) {
        self.world.write_model(@counter);
    }

    /// Game access methods
    fn get_game(self: @Store, game_id: u32) -> Game {
        self.world.read_model(game_id)
    }

    fn set_game(ref self: Store, game: Game) {
        self.world.write_model(@game);
    }

    /// Player management methods
    fn get_player(self: @Store, player: ContractAddress) -> Player {
        self.world.read_model(player)
    }

    fn set_player(ref self: Store, player: Player) {
        self.world.write_model(@player);
    }

    fn get_player_inventory(self: @Store, player: ContractAddress) -> PlayerInventory {
        self.world.read_model(player)
    }

    fn set_player_inventory(ref self: Store, inventory: PlayerInventory) {
        self.world.write_model(@inventory);
    }

    /// World item management - unified write operation
    fn get_world_item(self: @Store, game_id: u32, item_id: u32) -> WorldItem {
        self.world.read_model((game_id, item_id))
    }

    fn set_world_item(ref self: Store, item: WorldItem) {
        self.world.write_model(@item);
    }

    /// Level items management - unified write operation
    fn get_level_items(self: @Store, game_id: u32, level: u32) -> LevelItems {
        self.world.read_model((game_id, level))
    }

    fn set_level_items(ref self: Store, level_items: LevelItems) {
        self.world.write_model(@level_items);
    }

    // Event emission helper methods for standardized event publishing
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

    fn emit_game_created(ref self: Store, player: ContractAddress, game_id: u32, created_at: u64) {
        self.world.emit_event(@GameCreated { player, game_id, created_at });
    }
}
