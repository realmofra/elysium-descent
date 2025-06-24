// Main test orchestrator for Elysium Descent
// This file serves as the entry point for all tests

// The individual test files are imported at the lib.cairo level
// This file contains integration tests that verify the overall system

#[cfg(test)]
mod integration_tests {
    use starknet::{ContractAddress, contract_address_const};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
        WorldStorageTestTrait,
    };

    use elysium_descent::systems::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};
    use elysium_descent::systems::actions::{e_GameCreated, e_LevelStarted, e_ItemPickedUp};
    use elysium_descent::models::player::{Player, m_Player};
    use elysium_descent::models::game::{Game, LevelItems, GameCounter, m_Game, m_LevelItems, m_GameCounter};
    use elysium_descent::models::inventory::{PlayerInventory, m_PlayerInventory};
    use elysium_descent::models::world_state::{WorldItem, m_WorldItem};

    // Test constants
    fn PLAYER() -> ContractAddress {
        contract_address_const::<'PLAYER'>()
    }

    fn PLAYER2() -> ContractAddress {
        contract_address_const::<'PLAYER2'>()
    }

    // Basic setup function for simple tests
    fn setup_test_world() -> (WorldStorage, IActionsDispatcher) {
        let namespace_def = NamespaceDef {
            namespace: "elysium_001",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_LevelItems::TEST_CLASS_HASH),
                TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
                TestResource::Model(m_PlayerInventory::TEST_CLASS_HASH),
                TestResource::Model(m_WorldItem::TEST_CLASS_HASH),
                TestResource::Event(e_GameCreated::TEST_CLASS_HASH),
                TestResource::Event(e_LevelStarted::TEST_CLASS_HASH),
                TestResource::Event(e_ItemPickedUp::TEST_CLASS_HASH),
                TestResource::Contract(actions::TEST_CLASS_HASH),
            ].span(),
        };

        let mut world = spawn_test_world([namespace_def].span());
        
        // Sync permissions and initialize contracts
        let contracts = [
            ContractDefTrait::new(@"elysium_001", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"elysium_001")].span())
        ].span();
        
        world.sync_perms_and_inits(contracts);
        
        // Get system addresses using DNS
        let (actions_address, _) = world.dns(@"actions").unwrap();
        let actions = IActionsDispatcher { contract_address: actions_address };
        
        (world, actions)
    }
    
    #[test]
    fn test_world_setup_works() {
        // Basic test to ensure our test setup is working
        let (world, actions) = setup_test_world();
        
        // Verify we can create a game
        starknet::testing::set_contract_address(PLAYER());
        let game_id = actions.create_game();
        
        assert(game_id == 1, 'First game ID should be 1');
        
        // Verify game was created
        let game: Game = world.read_model(game_id);
        assert(game.player == PLAYER(), 'Game player should match');
    }

    #[test]
    fn test_multiple_players_isolated() {
        // Test that multiple players can use the system independently
        let (world, actions) = setup_test_world();
        
        // Player 1 creates game
        starknet::testing::set_contract_address(PLAYER());
        let game_id_1 = actions.create_game();
        
        // Player 2 creates game
        starknet::testing::set_contract_address(PLAYER2());
        let game_id_2 = actions.create_game();
        
        // Verify games are independent
        assert(game_id_1 != game_id_2, 'Game IDs should be different');
        
        let game_1: Game = world.read_model(game_id_1);
        let game_2: Game = world.read_model(game_id_2);
        
        assert(game_1.player == PLAYER(), 'Game 1 belongs to player 1');
        assert(game_2.player == PLAYER2(), 'Game 2 belongs to player 2');
    }
}

// Test summary:
// - setup.cairo: Centralized test world initialization
// - test_game_lifecycle.cairo: Game creation and player initialization
// - test_level_mechanics.cairo: Level progression and item spawning
// - test_inventory_behavior.cairo: Item pickup and inventory management
// - test_security.cairo: Security validation and authorization
// - test_workflows.cairo: End-to-end integration scenarios
//
// Total test coverage: All major game functions and user workflows