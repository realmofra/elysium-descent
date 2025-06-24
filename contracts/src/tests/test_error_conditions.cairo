/// Error Conditions Test Suite
///
/// Comprehensive testing of error conditions, validation rules, and edge cases that should
/// trigger assertions or panics. Uses #[should_panic] to verify proper error handling.

#[cfg(test)]
mod error_conditions_tests {
    use starknet::testing::set_contract_address;
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    // Component imports for direct testing
    use elysium_descent::components::game::{GameComponentTrait};
    use elysium_descent::components::inventory::{InventoryComponentTrait};

    // Centralized setup imports
    use elysium_descent::tests::setup::{
        spawn, Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem, PLAYER1, PLAYER2,
        get_test_timestamp,
    };
    use elysium_descent::helpers::store::{Store, StoreTrait};
    use elysium_descent::types::game::GameStatus;
    use elysium_descent::types::item::ItemType;

    // ==================== GAME OWNERSHIP AND SECURITY ERROR TESTS ====================

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('Not your game', 'ENTRYPOINT_FAILED'))]
    fn test_start_level_wrong_owner_should_panic() {
        let (world, systems, context) = spawn();

        // Player 1 creates a game
        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Player 2 tries to start a level in Player 1's game (should panic)
        set_contract_address(context.player2);
        systems.actions.start_level(game_id, 1);
    }

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('Not your game', 'ENTRYPOINT_FAILED'))]
    fn test_pickup_item_wrong_owner_should_panic() {
        let (mut world, systems, context) = spawn();

        // Player 1 creates a game and starts level
        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);

        // Create a test item in Player 1's game
        let test_item = WorldItem {
            game_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 1,
        };
        world.write_model_test(@test_item);

        // Player 2 tries to pickup item from Player 1's game (should panic)
        set_contract_address(context.player2);
        systems.actions.pickup_item(game_id, 1);
    }

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('Not your game', 'ENTRYPOINT_FAILED'))]
    fn test_game_component_start_level_wrong_owner() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Player 1 creates game via component
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);

        // Player 2 tries to start level in Player 1's game (should panic)
        GameComponentTrait::start_level(ref store, context.player2, game_id, 1);
    }

    // ==================== ITEM COLLECTION ERROR TESTS ====================

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('Item already collected', 'ENTRYPOINT_FAILED'))]
    fn test_pickup_already_collected_item_should_panic() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);

        // Create test item and mark as already collected
        let collected_item = WorldItem {
            game_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: true,
            level: 1,
        };
        world.write_model_test(@collected_item);

        // Try to pickup already collected item (should panic)
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);
    }

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('Inventory full', 'ENTRYPOINT_FAILED'))]
    fn test_pickup_item_inventory_full_should_panic() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);

        // Manually set inventory to full capacity
        let full_inventory = PlayerInventory {
            player: context.player1,
            health_potions: 25,
            survival_kits: 25,
            books: 0,
            capacity: 50 // Total items = 50, at capacity
        };
        world.write_model_test(@full_inventory);

        // Create test item
        let test_item = WorldItem {
            game_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 1,
        };
        world.write_model_test(@test_item);

        // Try to pickup item with full inventory (should panic)
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);
    }

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_pickup_nonexistent_item_should_panic() {
        let (world, systems, context) = spawn();

        // Player creates game and starts level
        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);

        // Try to pickup item that doesn't exist (should panic)
        systems.actions.pickup_item(game_id, 999);
    }

    // ==================== GAME STATE ERROR TESTS ====================

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_start_level_nonexistent_game_should_panic() {
        let (world, systems, context) = spawn();

        set_contract_address(context.player1);
        // Try to start level in non-existent game (should panic)
        systems.actions.start_level(999, 1);
    }

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('Game not in progress', 'ENTRYPOINT_FAILED'))]
    fn test_start_level_game_not_in_progress() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create game and manually set status to completed
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);

        let completed_game = Game {
            game_id,
            player: context.player1,
            status: GameStatus::Completed,
            current_level: 0,
            created_at: timestamp,
            score: 100,
        };
        world.write_model_test(@completed_game);

        // Try to start level in completed game (should panic)
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);
    }

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_get_nonexistent_game_should_panic() {
        let (world, systems, _context) = spawn();

        // Try to get stats for non-existent game (should panic when accessing)
        systems.actions.get_level_items(999, 1);
    }

    // ==================== DATA VALIDATION ERROR TESTS ====================

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_get_nonexistent_player_stats_should_panic() {
        let (world, systems, _context) = spawn();

        // Try to get stats for non-existent player (should panic)
        systems.actions.get_player_stats(starknet::contract_address_const::<0x999>());
    }

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_get_nonexistent_inventory_should_panic() {
        let (world, systems, _context) = spawn();

        // Try to get inventory for non-existent player (should panic)
        systems.actions.get_player_inventory(starknet::contract_address_const::<0x999>());
    }

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_get_nonexistent_level_items_should_panic() {
        let (world, systems, context) = spawn();

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Try to get level items for level that was never started (should panic)
        systems.actions.get_level_items(game_id, 999);
    }

    // ==================== COMPONENT LAYER ERROR TESTS ====================

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_component_pickup_nonexistent_world_item() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);

        // Try to pickup item that doesn't exist in world (should panic)
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 999);
    }

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_component_start_level_nonexistent_game() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Try to start level for non-existent game (should panic)
        GameComponentTrait::start_level(ref store, context.player1, 999, 1);
    }

    // ==================== EDGE CASE ERROR TESTS ====================

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_zero_address_player_operations() {
        let (world, systems, _context) = spawn();

        let zero_address = starknet::contract_address_const::<0>();
        set_contract_address(zero_address);

        // Try to create game with zero address (should panic)
        systems.actions.create_game();
    }

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('Item already collected', 'ENTRYPOINT_FAILED'))]
    fn test_double_pickup_same_item() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);

        // Create test item
        let test_item = WorldItem {
            game_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 1,
        };
        world.write_model_test(@test_item);

        // First pickup should succeed
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);

        // Second pickup of same item should panic
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);
    }

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('Inventory full', 'ENTRYPOINT_FAILED'))]
    fn test_exceed_inventory_capacity_gradually() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game with small inventory capacity
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);

        // Set inventory to near full (49/50)
        let near_full_inventory = PlayerInventory {
            player: context.player1, health_potions: 49, survival_kits: 0, books: 0, capacity: 50,
        };
        world.write_model_test(@near_full_inventory);

        // Create two test items
        let item1 = WorldItem {
            game_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 1,
        };
        let item2 = WorldItem {
            game_id,
            item_id: 2,
            item_type: ItemType::HealthPotion,
            x_position: 15,
            y_position: 25,
            is_collected: false,
            level: 1,
        };
        world.write_model_test(@item1);
        world.write_model_test(@item2);

        // First pickup should succeed (50/50)
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);

        // Second pickup should panic (would be 51/50)
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 2);
    }

    // ==================== CONSISTENCY ERROR TESTS ====================

    #[test]
    #[available_gas(30000000)]
    #[should_panic(expected: ('ENTRYPOINT_FAILED',))]
    fn test_access_level_items_before_level_start() {
        let (world, systems, context) = spawn();

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Try to access level items before starting any level (should panic)
        systems.actions.get_level_items(game_id, 1);
    }

    #[test]
    #[available_gas(60000000)]
    #[should_panic(expected: ('Not your game', 'ENTRYPOINT_FAILED'))]
    fn test_cross_game_item_pickup() {
        let (mut world, systems, context) = spawn();

        // Player 1 creates game 1
        set_contract_address(context.player1);
        let game1_id = systems.actions.create_game();
        systems.actions.start_level(game1_id, 1);

        // Player 2 creates game 2
        set_contract_address(context.player2);
        let game2_id = systems.actions.create_game();
        systems.actions.start_level(game2_id, 1);

        // Create item in game 1
        let item_in_game1 = WorldItem {
            game_id: game1_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 1,
        };
        world.write_model_test(@item_in_game1);

        // Player 2 tries to pickup item from game 1 (should panic)
        set_contract_address(context.player2);
        systems.actions.pickup_item(game1_id, 1);
    }
}
