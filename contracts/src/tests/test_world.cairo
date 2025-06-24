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
    use elysium_descent::models::game::{
        Game, LevelItems, GameCounter, m_Game, m_LevelItems, m_GameCounter,
    };
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
            ]
                .span(),
        };

        let mut world = spawn_test_world([namespace_def].span());

        // Sync permissions and initialize contracts using ContractDef
        let contracts = setup_contract_definitions();
        world.sync_perms_and_inits(contracts);

        // Get system addresses using DNS
        let (actions_address, _) = world.dns(@"actions").unwrap();
        let actions = IActionsDispatcher { contract_address: actions_address };

        (world, actions)
    }

    // Helper function that explicitly uses ContractDef type
    fn setup_contract_definitions() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"elysium_001", @"actions")
                .with_writer_of([dojo::utils::bytearray_hash(@"elysium_001")].span())
        ]
            .span()
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

        // Test additional models to use the imported types
        test_additional_models(world);
    }

    // Helper function to test additional model types that were imported
    fn test_additional_models(mut world: WorldStorage) {
        // Test GameCounter model usage using ModelStorageTest
        let counter = GameCounter { counter_id: 999999999, next_game_id: 3 };
        world.write_model_test(@counter);
        let read_counter: GameCounter = world.read_model(counter.counter_id);
        assert(read_counter.next_game_id == 3, 'Counter should be 3');

        // Test LevelItems model usage
        let level_items = LevelItems {
            game_id: 1,
            level: 1,
            total_health_potions: 5,
            total_survival_kits: 3,
            total_books: 2,
            collected_health_potions: 0,
            collected_survival_kits: 0,
            collected_books: 0,
        };
        world.write_model_test(@level_items);
        let read_level_items: LevelItems = world.read_model((1_u32, 1_u32));
        assert(read_level_items.total_health_potions == 5, 'Level items mismatch');

        // Test Player model explicitly
        let player_model = Player {
            player: PLAYER(),
            health: 80,
            max_health: 100,
            level: 2,
            experience: 150,
            items_collected: 3,
        };
        world.write_model_test(@player_model);
        let read_player: Player = world.read_model(PLAYER());
        assert(read_player.level == 2, 'Player level should be 2');

        // Test PlayerInventory model
        let inventory = PlayerInventory {
            player: PLAYER(), health_potions: 3, survival_kits: 1, books: 1, capacity: 15,
        };
        world.write_model_test(@inventory);
        let read_inventory: PlayerInventory = world.read_model(PLAYER());
        assert(read_inventory.health_potions == 3, 'Inventory mismatch');

        // Test WorldItem model
        let world_item = WorldItem {
            game_id: 1,
            item_id: 100,
            item_type: elysium_descent::types::item_types::ItemType::Book,
            x_position: 15,
            y_position: 25,
            is_collected: false,
            level: 1,
        };
        world.write_model_test(@world_item);
        let read_world_item: WorldItem = world.read_model((1_u32, 100_u32));
        assert(read_world_item.x_position == 15, 'World item position mismatch');
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


