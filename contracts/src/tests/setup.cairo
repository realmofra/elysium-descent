use starknet::{ContractAddress, contract_address_const};
use starknet::testing::set_contract_address;
use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo_cairo_test::{
    spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    WorldStorageTestTrait,
};

// Import our contracts and models
use elysium_descent::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
use elysium_descent::models::player::Player;
use elysium_descent::models::game::{Game, LevelItems, GameCounter};
use elysium_descent::models::inventory::PlayerInventory;
use elysium_descent::models::world_state::WorldItem;

// Test address constants
fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn PLAYER() -> ContractAddress {
    contract_address_const::<'PLAYER'>()
}

fn PLAYER2() -> ContractAddress {
    contract_address_const::<'PLAYER2'>()
}

fn OTHER_PLAYER() -> ContractAddress {
    contract_address_const::<'OTHER_PLAYER'>()
}

// System dispatchers struct
#[derive(Copy, Drop)]
pub struct Systems {
    pub actions: IActionsDispatcher,
}

// Test context data
#[derive(Copy, Drop)]
pub struct Context {
    pub player: ContractAddress,
    pub player2: ContractAddress,
    pub owner: ContractAddress,
}

// Setup namespace definition
#[inline]
fn setup_namespace() -> NamespaceDef {
    NamespaceDef {
        namespace: "elysium_001",
        resources: [
            // Models
            TestResource::Model(Player::TEST_CLASS_HASH),
            TestResource::Model(Game::TEST_CLASS_HASH),
            TestResource::Model(LevelItems::TEST_CLASS_HASH),
            TestResource::Model(GameCounter::TEST_CLASS_HASH),
            TestResource::Model(PlayerInventory::TEST_CLASS_HASH),
            TestResource::Model(WorldItem::TEST_CLASS_HASH),
            // Contracts
            TestResource::Contract(actions::TEST_CLASS_HASH),
        ].span(),
    }
}

// Setup contract definitions
#[inline]
fn setup_contracts() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"elysium_001", @"actions")
            .with_writer_of([dojo::utils::bytearray_hash(@"elysium_001")].span())
    ].span()
}

// Main spawn function that initializes the test world
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
    let systems = Systems {
        actions: IActionsDispatcher { contract_address: actions_address }
    };
    
    // Create test context
    let context = Context {
        player: PLAYER(),
        player2: PLAYER2(),
        owner: OWNER(),
    };
    
    (world, systems, context)
}

// Helper function to create a game for testing
pub fn create_test_game(systems: Systems, player: ContractAddress) -> u32 {
    set_contract_address(player);
    systems.actions.create_game()
}

// Helper function to start a level for testing
pub fn start_test_level(systems: Systems, player: ContractAddress, game_id: u32, level: u32) {
    set_contract_address(player);
    systems.actions.start_level(game_id, level);
}

// Helper function to get test timestamp
pub fn get_test_timestamp() -> u64 {
    1000_u64 // Fixed timestamp for consistent testing
}