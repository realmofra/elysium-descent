use starknet::{ContractAddress, contract_address_const, testing::set_contract_address};
use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage};
use dojo_cairo_test::{
    spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    WorldStorageTestTrait,
};

/// System imports
use elysium_descent::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
use elysium_descent::systems::actions::{e_GameCreated, e_LevelStarted, e_ItemPickedUp};

/// Model imports for direct usage
pub use elysium_descent::models::index::{
    Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem,
};

/// Model imports for TEST_CLASS_HASH
use elysium_descent::models::player::m_Player;
use elysium_descent::models::game::{m_Game, m_GameCounter, m_LevelItems};
use elysium_descent::models::inventory::m_PlayerInventory;
use elysium_descent::models::world_state::m_WorldItem;

/// Type imports
pub use elysium_descent::types::game_types::GameStatus;

/// Test address constants - make these proper public functions
pub fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

pub fn PLAYER1() -> ContractAddress {
    contract_address_const::<'PLAYER1'>()
}

pub fn PLAYER2() -> ContractAddress {
    contract_address_const::<'PLAYER2'>()
}

pub fn ADMIN() -> ContractAddress {
    contract_address_const::<'ADMIN'>()
}

/// System dispatchers struct
#[derive(Copy, Drop)]
pub struct Systems {
    pub actions: IActionsDispatcher,
}

/// Test context data
#[derive(Copy, Drop)]
pub struct Context {
    pub player1: ContractAddress,
    pub player2: ContractAddress,
    pub admin: ContractAddress,
    pub owner: ContractAddress,
}

/// Setup namespace definition with proper TEST_CLASS_HASH imports
#[inline]
fn setup_namespace() -> NamespaceDef {
    NamespaceDef {
        namespace: "elysium_001",
        resources: [
            // Models
            TestResource::Model(m_Player::TEST_CLASS_HASH),
            TestResource::Model(m_Game::TEST_CLASS_HASH),
            TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
            TestResource::Model(m_LevelItems::TEST_CLASS_HASH),
            TestResource::Model(m_PlayerInventory::TEST_CLASS_HASH),
            TestResource::Model(m_WorldItem::TEST_CLASS_HASH),
            // Events
            TestResource::Event(e_GameCreated::TEST_CLASS_HASH),
            TestResource::Event(e_LevelStarted::TEST_CLASS_HASH),
            TestResource::Event(e_ItemPickedUp::TEST_CLASS_HASH),
            // Contracts
            TestResource::Contract(actions::TEST_CLASS_HASH),
        ]
            .span(),
    }
}

/// Setup contract definitions
#[inline]
fn setup_contracts() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"elysium_001", @"actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"elysium_001")].span())
    ]
        .span()
}

/// Main spawn function that initializes the test world
#[inline]
pub fn spawn() -> (WorldStorage, Systems, Context) {
    // Set the caller to OWNER for world setup
    set_contract_address(OWNER());

    // Create test world with namespace
    let namespace_def = setup_namespace();
    let mut world = spawn_test_world([namespace_def].span());

    // Sync permissions and initialize contracts
    world.sync_perms_and_inits(setup_contracts());

    // Get system addresses using DNS
    let (actions_address, _) = world.dns(@"actions").unwrap();

    // Create Systems dispatcher
    let systems = Systems { actions: IActionsDispatcher { contract_address: actions_address } };

    // Create test context
    let context = Context {
        player1: PLAYER1(), player2: PLAYER2(), admin: ADMIN(), owner: OWNER(),
    };

    (world, systems, context)
}

/// Utility function for setting up comprehensive test world (alias for compatibility)
#[inline]
pub fn setup_comprehensive_world() -> (WorldStorage, IActionsDispatcher) {
    let (world, systems, _context) = spawn();
    (world, systems.actions)
}

/// Helper function to create a game for testing
pub fn create_test_game(systems: Systems, player: ContractAddress) -> u32 {
    set_contract_address(player);
    systems.actions.create_game()
}

// Helper function to start a level for testing
pub fn start_test_level(systems: Systems, player: ContractAddress, game_id: u32, level: u32) {
    set_contract_address(player);
    systems.actions.start_level(game_id, level);
}

// Helper function to clear events from contract
pub fn clear_events(address: ContractAddress) {
    loop {
        match starknet::testing::pop_log_raw(address) {
            core::option::Option::Some(_) => {},
            core::option::Option::None => { break; },
        };
    }
}

// Helper function to get test timestamp
pub fn get_test_timestamp() -> u64 {
    // Fixed timestamp for consistent testing
    1000_u64
}

/// Modern Store pattern - cleaner than repetitive helper functions
pub use elysium_descent::helpers::store::{Store, StoreTrait};

/// Test Store pattern usage
pub fn test_store_pattern(
    world: WorldStorage, player: ContractAddress,
) -> (Player, PlayerInventory) {
    // Explicitly use Store type
    let store: Store = StoreTrait::new(world);
    let player_data = store.get_player(player);
    let inventory = store.get_player_inventory(player);
    (player_data, inventory)
}

/// Helper that explicitly uses ModelStorage
pub fn direct_model_access(world: WorldStorage, player: ContractAddress) -> Player {
    // This uses ModelStorage trait
    world.read_model(player)
}
