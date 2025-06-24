use elysium_descent::models::player::Player;
use elysium_descent::models::inventory::PlayerInventory;
use elysium_descent::models::game::LevelItems;
use elysium_descent::types::item_types::ItemType;
use starknet::{get_block_timestamp, ContractAddress, get_caller_address};

/// Game events for external system notifications
#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct GameCreated {
    #[key]
    pub player: ContractAddress,
    pub game_id: u32,
    pub created_at: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct LevelStarted {
    #[key]
    pub player: ContractAddress,
    pub game_id: u32,
    pub level: u32,
    pub items_spawned: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::event]
pub struct ItemPickedUp {
    #[key]
    pub player: ContractAddress,
    pub game_id: u32,
    pub item_id: u32,
    pub item_type: ItemType,
    pub level: u32,
}

/// System interface defining available game actions
#[starknet::interface]
pub trait IActions<T> {
    fn create_game(ref self: T) -> u32;
    fn start_level(ref self: T, game_id: u32, level: u32);
    fn pickup_item(ref self: T, game_id: u32, item_id: u32) -> bool;
    fn get_player_stats(self: @T, player: ContractAddress) -> Player;
    fn get_player_inventory(self: @T, player: ContractAddress) -> PlayerInventory;
    fn get_level_items(self: @T, game_id: u32, level: u32) -> LevelItems;
}

/// Main game actions contract implementing the IActions interface
#[dojo::contract]
pub mod actions {
    use super::{
        IActions, Player, PlayerInventory, LevelItems, get_block_timestamp, get_caller_address,
        ContractAddress,
    };

    use elysium_descent::helpers::store::{Store, StoreTrait};
    use elysium_descent::components::inventory_component::{InventoryComponentTrait};
    use elysium_descent::components::game_component::{GameComponentTrait};

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create_game(ref self: ContractState) -> u32 {
            let mut store: Store = StoreTrait::new(self.world_default());
            let player = get_caller_address();
            let timestamp = get_block_timestamp();

            // Delegate game creation to the GameComponent following the Shinigami pattern
            GameComponentTrait::create_game(ref store, player, timestamp)
        }

        fn start_level(ref self: ContractState, game_id: u32, level: u32) {
            let mut store: Store = StoreTrait::new(self.world_default());
            let player = get_caller_address();

            // Delegate level management to the GameComponent layer
            GameComponentTrait::start_level(ref store, player, game_id, level);
        }

        fn pickup_item(ref self: ContractState, game_id: u32, item_id: u32) -> bool {
            let mut store: Store = StoreTrait::new(self.world_default());
            let player = get_caller_address();

            // Validate that the caller owns the specified game
            let game = StoreTrait::get_game(@store, game_id);
            assert(game.player == player, 'Not your game');

            // Delegate item pickup logic to the InventoryComponent layer
            InventoryComponentTrait::pickup_item(ref store, player, game_id, item_id)
        }

        fn get_player_stats(self: @ContractState, player: ContractAddress) -> Player {
            let store: Store = StoreTrait::new(self.world_default());
            StoreTrait::get_player(@store, player)
        }

        fn get_player_inventory(self: @ContractState, player: ContractAddress) -> PlayerInventory {
            let store: Store = StoreTrait::new(self.world_default());
            StoreTrait::get_player_inventory(@store, player)
        }

        fn get_level_items(self: @ContractState, game_id: u32, level: u32) -> LevelItems {
            let store: Store = StoreTrait::new(self.world_default());
            StoreTrait::get_level_items(@store, game_id, level)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Access the default world storage for the "elysium_001" namespace.
        /// This function provides a consistent way to access the world instance.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"elysium_001")
        }
    }
}
