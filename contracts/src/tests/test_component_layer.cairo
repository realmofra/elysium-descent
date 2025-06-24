/// Component Layer Test Suite
///
/// Direct testing of GameComponent and InventoryComponent logic following Shinigami architecture.
/// Tests focus on component-level business logic, data transformations, and validation rules.

#[cfg(test)]
mod component_layer_tests {
    use dojo::model::ModelStorageTest;

    // Component imports for direct testing
    use elysium_descent::components::game::{GameComponentTrait};
    use elysium_descent::components::inventory::{InventoryComponentTrait};

    // Centralized setup imports
    use elysium_descent::tests::setup::{
        spawn, Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem,
        get_test_timestamp,
    };
    use elysium_descent::helpers::store::{Store, StoreTrait};
    use elysium_descent::types::game::GameStatus;
    use elysium_descent::types::item::ItemType;

    // ==================== GAME COMPONENT DIRECT TESTS ====================

    #[test]
    #[available_gas(30000000)]
    fn test_game_component_create_game_direct() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Test GameComponent.create_game directly
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);

        // Verify game creation via component
        assert(game_id == 1, 'First game ID 1');

        let game: Game = store.get_game(game_id);
        assert(game.player == context.player1, 'Game player wrong');
        assert(game.status == GameStatus::InProgress, 'Game status wrong');
        assert(game.current_level == 0, 'Initial level 0');
        assert(game.score == 0, 'Initial score 0');
        assert(game.created_at == timestamp, 'Created timestamp wrong');

        // Verify player initialization via component
        let player: Player = store.get_player(context.player1);
        assert(player.health == 100, 'Initial health 100');
        assert(player.max_health == 100, 'Max health 100');
        assert(player.level == 1, 'Player level 1');
        assert(player.experience == 0, 'Initial experience 0');
        assert(player.items_collected == 0, 'Initial items wrong');

        // Verify inventory initialization via component
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);
        assert(inventory.health_potions == 0, 'Initial potions wrong');
        assert(inventory.survival_kits == 0, 'Initial kits wrong');
        assert(inventory.books == 0, 'Initial books 0');
        assert(inventory.capacity == 50, 'Initial capacity 50');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_game_component_counter_management() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        let timestamp = get_test_timestamp();

        // Create multiple games via component to test counter
        let game1_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        let game2_id = GameComponentTrait::create_game(ref store, context.player2, timestamp + 1);
        let game3_id = GameComponentTrait::create_game(ref store, context.player1, timestamp + 2);

        // Verify counter increments properly
        assert(game1_id == 1, 'First game ID 1');
        assert(game2_id == 2, 'Second game ID 2');
        assert(game3_id == 3, 'Third game ID 3');

        // Verify games belong to correct players
        let game1: Game = store.get_game(game1_id);
        let game2: Game = store.get_game(game2_id);
        let game3: Game = store.get_game(game3_id);

        assert(game1.player == context.player1, 'Game 1 player wrong');
        assert(game2.player == context.player2, 'Game 2 player wrong');
        assert(game3.player == context.player1, 'Game 3 player wrong');

        // Verify counter state
        let counter: GameCounter = store.get_game_counter();
        assert(counter.next_game_id == 4, 'Counter wrong');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_game_component_start_level_direct() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create game via component
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);

        // Test start_level component directly
        let items_spawned = GameComponentTrait::start_level(ref store, context.player1, game_id, 3);

        // Verify level was set
        let game: Game = store.get_game(game_id);
        assert(game.current_level == 3, 'Level 3');

        // Verify level items were created
        let level_items: LevelItems = store.get_level_items(game_id, 3);
        assert(level_items.game_id == game_id, 'Level items game ID wrong');
        assert(level_items.level == 3, 'Level items level wrong');
        assert(level_items.total_health_potions == 6, 'L3 potions wrong');
        assert(level_items.total_survival_kits == 2, 'L3 kits wrong');
        assert(level_items.total_books == 1, 'Level 3 has 1 book');

        // Verify collection counts start at 0
        assert(level_items.collected_health_potions == 0, 'Collected potions start at 0');
        assert(level_items.collected_survival_kits == 0, 'Collected kits start at 0');
        assert(level_items.collected_books == 0, 'Collected books start at 0');

        // Verify items spawned count
        let expected_items = level_items.total_health_potions
            + level_items.total_survival_kits
            + level_items.total_books;
        assert(items_spawned == expected_items, 'Items spawned count wrong');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_game_component_level_calculations() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);

        // Test different level calculations
        GameComponentTrait::start_level(ref store, context.player1, game_id, 0);
        let level0: LevelItems = store.get_level_items(game_id, 0);
        assert(level0.total_health_potions == 3, 'Level 0 health potions');
        assert(level0.total_survival_kits == 0, 'Level 0 survival kits');
        assert(level0.total_books == 0, 'Level 0 books');

        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);
        let level1: LevelItems = store.get_level_items(game_id, 1);
        assert(level1.total_health_potions == 4, 'Level 1 health potions');
        assert(level1.total_survival_kits == 1, 'Level 1 survival kits');
        assert(level1.total_books == 0, 'Level 1 books');

        GameComponentTrait::start_level(ref store, context.player1, game_id, 15);
        let level15: LevelItems = store.get_level_items(game_id, 15);
        assert(level15.total_health_potions == 10, 'Level 15 max health potions');
        assert(level15.total_survival_kits == 3, 'Level 15 max survival kits');
        assert(level15.total_books == 2, 'Level 15 max books');
    }

    // ==================== INVENTORY COMPONENT DIRECT TESTS ====================

    #[test]
    #[available_gas(60000000)]
    fn test_inventory_component_pickup_item_direct() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level via component
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);

        // Create a test world item manually for direct component testing
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

        // Test pickup_item component directly
        let pickup_result = InventoryComponentTrait::pickup_item(
            ref store, context.player1, game_id, 1,
        );
        assert(pickup_result == true, 'Pickup should succeed');

        // Verify inventory was updated
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);
        assert(inventory.health_potions == 1, 'Health potions 1');
        assert(inventory.survival_kits == 0, 'Survival kits should remain 0');
        assert(inventory.books == 0, 'Books should remain 0');

        // Verify player stats were updated
        let player: Player = store.get_player(context.player1);
        assert(player.experience == 10, 'Experience 10');
        assert(player.items_collected == 1, 'Items collected 1');
        assert(player.level == 1, 'Level should remain 1');

        // Verify world item was marked as collected
        let updated_item: WorldItem = store.get_world_item(game_id, 1);
        assert(updated_item.is_collected == true, 'Item marked collected');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_inventory_component_different_item_types() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 3);

        // Create different types of test items
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

        // Test picking up each type
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 2);
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 3);

        // Verify inventory counts
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);
        assert(inventory.health_potions == 1, 'Health potions 1');
        assert(inventory.survival_kits == 1, 'Survival kits 1');
        assert(inventory.books == 1, 'Books 1');

        // Verify player progression
        let player: Player = store.get_player(context.player1);
        assert(player.experience == 30, 'Experience 30');
        assert(player.items_collected == 3, 'Items collected 3');
    }

    #[test]
    #[available_gas(120000000)]
    fn test_inventory_component_level_progression() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game and level
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);

        // Create enough items to trigger level progression
        let mut item_id = 1;
        loop {
            if item_id > 10 {
                break;
            }
            let test_item = WorldItem {
                game_id,
                item_id,
                item_type: ItemType::HealthPotion,
                x_position: 10,
                y_position: 20,
                is_collected: false,
                level: 1,
            };
            world.write_model_test(@test_item);
            item_id += 1;
        };

        // Initial state
        let initial_player: Player = store.get_player(context.player1);
        assert(initial_player.level == 1, 'Initial level 1');
        assert(initial_player.health == 100, 'Initial health 100');
        assert(initial_player.max_health == 100, 'Max health wrong');

        // Pick up items to gain experience
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1); // 10 exp
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 2); // 20 exp
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 3); // 30 exp

        // Check no level up yet
        let mid_player: Player = store.get_player(context.player1);
        assert(mid_player.level == 1, 'Should still be level 1');
        assert(mid_player.experience == 30, 'Experience 30');

        // Pick up more items to trigger level up (need 100+ exp for level 2)
        let mut pickup_count = 4;
        loop {
            if pickup_count > 10 {
                break;
            }
            InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, pickup_count);
            pickup_count += 1;
        };

        // Verify level progression
        let final_player: Player = store.get_player(context.player1);
        assert(final_player.level == 2, 'Should be level 2');
        assert(final_player.experience == 100, 'Experience 100');
        assert(final_player.health == 110, 'Health wrong');
        assert(final_player.max_health == 110, 'Max health wrong');
        assert(final_player.items_collected == 10, 'Items collected 10');
    }

    // ==================== COMPONENT INTEGRATION TESTS ====================

    #[test]
    #[available_gas(60000000)]
    fn test_components_integration_workflow() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Test complete workflow using components directly
        let timestamp = get_test_timestamp();

        // Step 1: Create game via GameComponent
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);

        // Step 2: Start level via GameComponent
        let items_spawned = GameComponentTrait::start_level(ref store, context.player1, game_id, 2);
        assert(items_spawned == 6, 'Level 2 spawns 6 items'); // 5 potions + 1 kit + 0 books

        // Step 3: Create test items for pickup
        let test_item1 = WorldItem {
            game_id,
            item_id: 1,
            item_type: ItemType::HealthPotion,
            x_position: 10,
            y_position: 20,
            is_collected: false,
            level: 2,
        };
        let test_item2 = WorldItem {
            game_id,
            item_id: 2,
            item_type: ItemType::SurvivalKit,
            x_position: 15,
            y_position: 25,
            is_collected: false,
            level: 2,
        };
        world.write_model_test(@test_item1);
        world.write_model_test(@test_item2);

        // Step 4: Pick up items via InventoryComponent
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);
        InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 2);

        // Verify final state
        let game: Game = store.get_game(game_id);
        let player: Player = store.get_player(context.player1);
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);
        let level_items: LevelItems = store.get_level_items(game_id, 2);

        assert(game.current_level == 2, 'Game level 2');
        assert(player.experience == 20, 'Player experience 20');
        assert(player.items_collected == 2, 'Player items wrong');
        assert(inventory.health_potions == 1, 'Inventory potions wrong');
        assert(inventory.survival_kits == 1, 'Inventory kits wrong');
        assert(level_items.total_health_potions == 5, 'Level potions wrong');
        assert(level_items.total_survival_kits == 1, 'Level kits wrong');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_component_validation_and_assertions() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Setup game
        let timestamp = get_test_timestamp();
        let game_id = GameComponentTrait::create_game(ref store, context.player1, timestamp);
        GameComponentTrait::start_level(ref store, context.player1, game_id, 1);

        // Create test item for validation tests
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

        // Test successful pickup first
        let result = InventoryComponentTrait::pickup_item(ref store, context.player1, game_id, 1);
        assert(result == true, 'First pickup should succeed');

        // Verify item is marked as collected
        let collected_item: WorldItem = store.get_world_item(game_id, 1);
        assert(collected_item.is_collected == true, 'Item collected');
        // Note: Error condition tests (assertions) in test_error_conditions.cairo
    // with #[should_panic] attribute since components use assert! for validation
    }
}
