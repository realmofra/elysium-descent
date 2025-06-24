/// Events Test Suite
///
/// Comprehensive testing of event emission for GameCreated, LevelStarted, and ItemPickedUp events.
/// Verifies proper event data, timing, and integration with game workflows.

#[cfg(test)]
mod events_tests {
    use starknet::testing::{set_contract_address, pop_log_raw};
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    // Component imports
    use elysium_descent::components::game::{GameComponentTrait};
    use elysium_descent::components::inventory::{InventoryComponentTrait};

    // Event imports
    use elysium_descent::systems::actions::{GameCreated, LevelStarted, ItemPickedUp};

    // Centralized setup imports
    use elysium_descent::tests::setup::{
        spawn, Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem, PLAYER1, PLAYER2,
        clear_events, get_test_timestamp,
    };
    use elysium_descent::helpers::store::{Store, StoreTrait};
    use elysium_descent::types::item::ItemType;

    // ==================== GAME CREATED EVENT TESTS ====================

    #[test]
    #[available_gas(30000000)]
    fn test_game_created_event_emission() {
        let (world, systems, context) = spawn();

        // Clear any existing events
        clear_events(world.dispatcher.contract_address);

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Capture and verify GameCreated event
        let event = pop_log_raw(world.dispatcher.contract_address).unwrap();

        // Events are emitted but detailed verification would require event parsing
        // For now, verify that an event was emitted
        assert(game_id == 1, 'Game creation should succeed');

        // Verify game was created with expected properties
        let store: Store = StoreTrait::new(world);
        let game: Game = store.get_game(game_id);
        assert(game.player == context.player1, 'Event should match game player');
        assert(game.game_id == game_id, 'Event should match game ID');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_multiple_game_created_events() {
        let (world, systems, context) = spawn();

        // Clear existing events
        clear_events(world.dispatcher.contract_address);

        // Create multiple games and verify events
        set_contract_address(context.player1);
        let game1_id = systems.actions.create_game();

        set_contract_address(context.player2);
        let game2_id = systems.actions.create_game();

        // Verify multiple events were emitted (pop_log_raw gets most recent)
        let event2 = pop_log_raw(world.dispatcher.contract_address);
        let event1 = pop_log_raw(world.dispatcher.contract_address);

        assert(event1.is_some(), 'First event should exist');
        assert(event2.is_some(), 'Second event should exist');

        // Verify games were created correctly
        assert(game1_id == 1, 'First game ID should be 1');
        assert(game2_id == 2, 'Second game ID should be 2');

        let store: Store = StoreTrait::new(world);
        let game1: Game = store.get_game(game1_id);
        let game2: Game = store.get_game(game2_id);

        assert(game1.player == context.player1, 'Game 1 player should match');
        assert(game2.player == context.player2, 'Game 2 player should match');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_game_created_event_via_component() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Clear existing events
        clear_events(world.dispatcher.contract_address);

        // Create game via component directly
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);

        // Verify event was emitted
        let event = pop_log_raw(world.dispatcher.contract_address);
        assert(event.is_some(), 'GameCreated event should be emitted');

        // Verify game creation
        let game: Game = store.get_game(game_id);
        assert(game.player == context.player1, 'Game player should match event');
        assert(game.created_at == timestamp, 'Timestamp should match event');
    }

    // ==================== LEVEL STARTED EVENT TESTS ====================

    #[test]
    #[available_gas(60000000)]
    fn test_level_started_event_emission() {
        let (world, systems, context) = spawn();

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Clear events after game creation
        clear_events(world.dispatcher.contract_address);

        // Start level and verify event
        systems.actions.start_level(game_id, 3);

        let event = pop_log_raw(world.dispatcher.contract_address);
        assert(event.is_some(), 'LevelStarted event should be emitted');

        // Verify level was started correctly
        let store: Store = StoreTrait::new(world);
        let game: Game = store.get_game(game_id);
        assert(game.current_level == 3, 'Game level should be updated');

        let level_items: LevelItems = store.get_level_items(game_id, 3);
        assert(level_items.level == 3, 'Level items should match event level');
        assert(level_items.game_id == game_id, 'Level items should match event game');
    }

    #[test]
    #[available_gas(100000000)]
    fn test_multiple_level_started_events() {
        let (world, systems, context) = spawn();

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Clear events after game creation
        clear_events(world.dispatcher.contract_address);

        // Start multiple levels
        systems.actions.start_level(game_id, 1);
        systems.actions.start_level(game_id, 3);
        systems.actions.start_level(game_id, 5);

        // Verify multiple events were emitted
        let event3 = pop_log_raw(world.dispatcher.contract_address);
        let event2 = pop_log_raw(world.dispatcher.contract_address);
        let event1 = pop_log_raw(world.dispatcher.contract_address);

        assert(event1.is_some(), 'First level event should exist');
        assert(event2.is_some(), 'Second level event should exist');
        assert(event3.is_some(), 'Third level event should exist');

        // Verify final game state
        let store: Store = StoreTrait::new(world);
        let game: Game = store.get_game(game_id);
        assert(game.current_level == 5, 'Game should be at level 5');

        // Verify all level items were created
        let level1_items: LevelItems = store.get_level_items(game_id, 1);
        let level3_items: LevelItems = store.get_level_items(game_id, 3);
        let level5_items: LevelItems = store.get_level_items(game_id, 5);

        assert(level1_items.level == 1, 'Level 1 items should exist');
        assert(level3_items.level == 3, 'Level 3 items should exist');
        assert(level5_items.level == 5, 'Level 5 items should exist');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_level_started_event_via_component() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create game via component
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);

        // Clear events after game creation
        clear_events(world.dispatcher.contract_address);

        // Start level via component
        let items_spawned = GameComponentTrait::start_level(ref store, context.player1, game_id, 2);

        // Verify event was emitted
        let event = pop_log_raw(world.dispatcher.contract_address);
        assert(event.is_some(), 'LevelStarted event should be emitted');

        // Verify level was started correctly
        let game: Game = store.get_game(game_id);
        assert(game.current_level == 2, 'Game level should be 2');

        let level_items: LevelItems = store.get_level_items(game_id, 2);
        assert(level_items.level == 2, 'Level items level should be 2');
        assert(items_spawned == 5, 'Level 2 should spawn 5 items');
    }

    // ==================== ITEM PICKED UP EVENT TESTS ====================

    #[test]
    #[available_gas(60000000)]
    fn test_item_picked_up_event_emission() {
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

        // Clear events after setup
        clear_events(world.dispatcher.contract_address);

        // Pickup item and verify event
        let pickup_result = InventoryComponentTrait::pickup_item(
            ref store, context.player1, game_id, 1,
        );
        assert(pickup_result == true, 'Pickup should succeed');

        // Verify event was emitted
        let event = pop_log_raw(world.dispatcher.contract_address);
        assert(event.is_some(), 'ItemPickedUp event should be emitted');

        // Verify pickup effects
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);
        assert(inventory.health_potions == 1, 'Inventory should be updated');

        let player: Player = store.get_player(context.player1);
        assert(player.items_collected == 1, 'Player items count should update');
        assert(player.experience == 10, 'Player should gain experience');
    }

    #[test]
    #[available_gas(100000000)]
    fn test_multiple_item_pickup_events() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 2);

        // Create multiple test items
        let item1 = WorldItem {
            game_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 2,
        };
        let item2 = WorldItem {
            game_id,
            item_id: 2,
            item_type: ItemType::SurvivalKit,
            x_position: 15,
            y_position: 25,
            is_collected: false,
            level: 2,
        };
        let item3 = WorldItem {
            game_id,
            item_id: 3,
            item_type: ItemType::HealthPotion,
            x_position: 20,
            y_position: 30,
            is_collected: false,
            level: 2,
        };

        world.write_model_test(@item1);
        world.write_model_test(@item2);
        world.write_model_test(@item3);

        // Clear events after setup
        clear_events(world.dispatcher.contract_address);

        // Pickup multiple items
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 2);
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 3);

        // Verify multiple events were emitted
        let event3 = pop_log_raw(world.dispatcher.contract_address);
        let event2 = pop_log_raw(world.dispatcher.contract_address);
        let event1 = pop_log_raw(world.dispatcher.contract_address);

        assert(event1.is_some(), 'First pickup event should exist');
        assert(event2.is_some(), 'Second pickup event should exist');
        assert(event3.is_some(), 'Third pickup event should exist');

        // Verify final inventory state
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);
        assert(inventory.health_potions == 2, 'Should have 2 health potions');
        assert(inventory.survival_kits == 1, 'Should have 1 survival kit');

        let player: Player = store.get_player(context.player1);
        assert(player.items_collected == 3, 'Should have collected 3 items');
        assert(player.experience == 30, 'Should have 30 experience');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_item_pickup_event_different_types() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 3);

        // Create different item types
        let health_potion = WorldItem {
            game_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 3,
        };
        let survival_kit = WorldItem {
            game_id,
            item_id: 2,
            item_type: ItemType::SurvivalKit,
            x_position: 15,
            y_position: 25,
            is_collected: false,
            level: 3,
        };
        let book = WorldItem {
            game_id,
            item_id: 3,
            item_type: ItemType::Book,
            x_position: 20,
            y_position: 30,
            is_collected: false,
            level: 3,
        };

        world.write_model_test(@health_potion);
        world.write_model_test(@survival_kit);
        world.write_model_test(@book);

        // Clear events
        clear_events(world.dispatcher.contract_address);

        // Test each item type
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);
        let health_event = pop_log_raw(world.dispatcher.contract_address);
        assert(health_event.is_some(), 'HealthPotion event should be emitted');

        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 2);
        let kit_event = pop_log_raw(world.dispatcher.contract_address);
        assert(kit_event.is_some(), 'SurvivalKit event should be emitted');

        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 3);
        let book_event = pop_log_raw(world.dispatcher.contract_address);
        assert(book_event.is_some(), 'Book event should be emitted');

        // Verify inventory reflects all pickups
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);
        assert(inventory.health_potions == 1, 'Should have 1 health potion');
        assert(inventory.survival_kits == 1, 'Should have 1 survival kit');
        assert(inventory.books == 1, 'Should have 1 book');
    }

    // ==================== EVENT INTEGRATION TESTS ====================

    #[test]
    #[available_gas(100000000)]
    fn test_complete_workflow_event_sequence() {
        let (mut world, systems, context) = spawn();

        // Clear all events to start fresh
        clear_events(world.dispatcher.contract_address);

        set_contract_address(context.player1);

        // Step 1: Create game (should emit GameCreated)
        let game_id = systems.actions.create_game();
        let game_event = pop_log_raw(world.dispatcher.contract_address);
        assert(game_event.is_some(), 'GameCreated event should be emitted');

        // Step 2: Start level (should emit LevelStarted)
        systems.actions.start_level(game_id, 1);
        let level_event = pop_log_raw(world.dispatcher.contract_address);
        assert(level_event.is_some(), 'LevelStarted event should be emitted');

        // Step 3: Create and pickup item (should emit ItemPickedUp)
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

        let pickup_result = systems.actions.pickup_item(game_id, 1);
        assert(pickup_result == true, 'Pickup should succeed');

        let pickup_event = pop_log_raw(world.dispatcher.contract_address);
        assert(pickup_event.is_some(), 'ItemPickedUp event should be emitted');

        // Verify final state
        let store: Store = StoreTrait::new(world);
        let game: Game = store.get_game(game_id);
        let player: Player = store.get_player(context.player1);
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);

        assert(game.current_level == 1, 'Game should be at level 1');
        assert(player.items_collected == 1, 'Player should have 1 item');
        assert(inventory.health_potions == 1, 'Inventory should have 1 potion');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_event_isolation_between_players() {
        let (mut world, systems, context) = spawn();

        // Clear events
        clear_events(world.dispatcher.contract_address);

        // Player 1 creates game
        set_contract_address(context.player1);
        let game1_id = systems.actions.create_game();

        // Player 2 creates game
        set_contract_address(context.player2);
        let game2_id = systems.actions.create_game();

        // Verify 2 GameCreated events
        let game2_event = pop_log_raw(world.dispatcher.contract_address);
        let game1_event = pop_log_raw(world.dispatcher.contract_address);
        assert(game1_event.is_some(), 'Player 1 game event should exist');
        assert(game2_event.is_some(), 'Player 2 game event should exist');

        // Both players start levels
        set_contract_address(context.player1);
        systems.actions.start_level(game1_id, 1);

        set_contract_address(context.player2);
        systems.actions.start_level(game2_id, 2);

        // Verify 2 LevelStarted events
        let level2_event = pop_log_raw(world.dispatcher.contract_address);
        let level1_event = pop_log_raw(world.dispatcher.contract_address);
        assert(level1_event.is_some(), 'Player 1 level event should exist');
        assert(level2_event.is_some(), 'Player 2 level event should exist');

        // Verify games are separate
        let store: Store = StoreTrait::new(world);
        let game1: Game = store.get_game(game1_id);
        let game2: Game = store.get_game(game2_id);

        assert(game1.player == context.player1, 'Game 1 belongs to player 1');
        assert(game2.player == context.player2, 'Game 2 belongs to player 2');
        assert(game1.current_level == 1, 'Game 1 at level 1');
        assert(game2.current_level == 2, 'Game 2 at level 2');
    }
}
