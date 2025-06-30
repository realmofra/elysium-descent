/// Helpers Test Suite
///
/// Comprehensive testing of helper functions, Store pattern implementation, and utility methods.
/// Tests the abstraction layer between systems and models following Shinigami architecture.

#[cfg(test)]
mod helpers_tests {
    use dojo::model::{ModelStorage, ModelStorageTest};

    // Centralized setup imports
    use elysium_descent::tests::setup::{
        spawn, Player, Game, GameCounter, LevelItems, PlayerInventory, WorldItem,
        get_test_timestamp,
    };
    use elysium_descent::helpers::store::{Store, StoreTrait};
    use elysium_descent::types::game::GameStatus;
    use elysium_descent::types::item::ItemType;
    use elysium_descent::models::game::GAME_COUNTER_ID;

    // ==================== STORE PATTERN BASIC OPERATIONS ====================

    #[test]
    #[available_gas(30000000)]
    fn test_store_initialization() {
        let (world, _systems, _context) = spawn();
        let store: Store = StoreTrait::new(world);

        // Test that store can be created and used
        // Verify store functionality by testing a basic operation
        let test_counter = store.get_game_counter();
        assert(test_counter.counter_id == 999999999, 'Store should work');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_store_player_operations() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create test player
        let test_player = Player {
            player: context.player1,
            health: 80,
            max_health: 100,
            level: 2,
            experience: 150,
            items_collected: 5,
        };

        // Test store set/get for player
        store.set_player(test_player);
        let retrieved_player: Player = store.get_player(context.player1);

        assert(retrieved_player.player == context.player1, 'Player address should match');
        assert(retrieved_player.health == 80, 'Health should be 80');
        assert(retrieved_player.max_health == 100, 'Max health should be 100');
        assert(retrieved_player.level == 2, 'Level should be 2');
        assert(retrieved_player.experience == 150, 'Experience should be 150');
        assert(retrieved_player.items_collected == 5, 'Items collected should be 5');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_store_game_operations() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        let timestamp = get_test_timestamp();

        // Create test game
        let test_game = Game {
            game_id: 42,
            player: context.player1,
            status: GameStatus::InProgress,
            current_level: 5,
            created_at: timestamp,
            score: 1000,
        };

        // Test store set/get for game
        store.set_game(test_game);
        let retrieved_game: Game = store.get_game(42);

        assert(retrieved_game.game_id == 42, 'Game ID should be 42');
        assert(retrieved_game.player == context.player1, 'Player should match');
        assert(retrieved_game.status == GameStatus::InProgress, 'Status should be InProgress');
        assert(retrieved_game.current_level == 5, 'Level should be 5');
        assert(retrieved_game.created_at == timestamp, 'Timestamp should match');
        assert(retrieved_game.score == 1000, 'Score should be 1000');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_store_inventory_operations() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create test inventory
        let test_inventory = PlayerInventory {
            player: context.player1, health_potions: 10, survival_kits: 5, books: 3, capacity: 75,
        };

        // Test store set/get for inventory
        store.set_player_inventory(test_inventory);
        let retrieved_inventory: PlayerInventory = store.get_player_inventory(context.player1);

        assert(retrieved_inventory.player == context.player1, 'Player should match');
        assert(retrieved_inventory.health_potions == 10, 'Health potions should be 10');
        assert(retrieved_inventory.survival_kits == 5, 'Survival kits should be 5');
        assert(retrieved_inventory.books == 3, 'Books should be 3');
        assert(retrieved_inventory.capacity == 75, 'Capacity should be 75');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_store_level_items_operations() {
        let (world, _systems, _context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create test level items
        let test_level_items = LevelItems {
            game_id: 123,
            level: 7,
            total_health_potions: 15,
            total_survival_kits: 8,
            total_books: 4,
            collected_health_potions: 5,
            collected_survival_kits: 2,
            collected_books: 1,
        };

        // Test store set/get for level items
        store.set_level_items(test_level_items);
        let retrieved_level_items: LevelItems = store.get_level_items(123, 7);

        assert(retrieved_level_items.game_id == 123, 'Game ID should be 123');
        assert(retrieved_level_items.level == 7, 'Level should be 7');
        assert(retrieved_level_items.total_health_potions == 15, 'Total potions should be 15');
        assert(retrieved_level_items.total_survival_kits == 8, 'Total kits should be 8');
        assert(retrieved_level_items.total_books == 4, 'Total books should be 4');
        assert(
            retrieved_level_items.collected_health_potions == 5, 'Collected potions should be 5',
        );
        assert(retrieved_level_items.collected_survival_kits == 2, 'Collected kits should be 2');
        assert(retrieved_level_items.collected_books == 1, 'Collected books should be 1');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_store_world_item_operations() {
        let (world, _systems, _context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create test world item
        let test_world_item = WorldItem {
            game_id: 456,
            item_id: 789,
            item_type: ItemType::SurvivalKit,
            x_position: 25,
            y_position: 35,
            is_collected: false,
            level: 3,
        };

        // Test store set/get for world item
        store.set_world_item(test_world_item);
        let retrieved_world_item: WorldItem = store.get_world_item(456, 789);

        assert(retrieved_world_item.game_id == 456, 'Game ID should be 456');
        assert(retrieved_world_item.item_id == 789, 'Item ID should be 789');
        assert(
            retrieved_world_item.item_type == ItemType::SurvivalKit,
            'Item type should be SurvivalKit',
        );
        assert(retrieved_world_item.x_position == 25, 'X position should be 25');
        assert(retrieved_world_item.y_position == 35, 'Y position should be 35');
        assert(retrieved_world_item.is_collected == false, 'Should not be collected');
        assert(retrieved_world_item.level == 3, 'Level should be 3');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_store_game_counter_operations() {
        let (world, _systems, _context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create test game counter
        let test_counter = GameCounter { counter_id: GAME_COUNTER_ID, next_game_id: 42 };

        // Test store set/get for game counter
        store.set_game_counter(test_counter);
        let retrieved_counter: GameCounter = store.get_game_counter();

        assert(retrieved_counter.counter_id == GAME_COUNTER_ID, 'Counter ID should match');
        assert(retrieved_counter.next_game_id == 42, 'Next game ID should be 42');
    }

    // ==================== STORE PATTERN COMPOSITE OPERATIONS ====================

    #[test]
    #[available_gas(60000000)]
    fn test_store_multiple_operations() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        let timestamp = get_test_timestamp();

        // Set up multiple related entities
        let player = Player {
            player: context.player1,
            health: 90,
            max_health: 100,
            level: 3,
            experience: 250,
            items_collected: 8,
        };
        let game = Game {
            game_id: 1,
            player: context.player1,
            status: GameStatus::InProgress,
            current_level: 3,
            created_at: timestamp,
            score: 500,
        };
        let inventory = PlayerInventory {
            player: context.player1, health_potions: 4, survival_kits: 2, books: 2, capacity: 50,
        };
        let level_items = LevelItems {
            game_id: 1,
            level: 3,
            total_health_potions: 6,
            total_survival_kits: 2,
            total_books: 1,
            collected_health_potions: 4,
            collected_survival_kits: 2,
            collected_books: 1,
        };

        // Store all entities
        store.set_player(player);
        store.set_game(game);
        store.set_player_inventory(inventory);
        store.set_level_items(level_items);

        // Retrieve and verify all entities
        let retrieved_player: Player = store.get_player(context.player1);
        let retrieved_game: Game = store.get_game(1);
        let retrieved_inventory: PlayerInventory = store.get_player_inventory(context.player1);
        let retrieved_level_items: LevelItems = store.get_level_items(1, 3);

        // Verify relationships and consistency
        assert(retrieved_player.player == retrieved_game.player, 'Player-game relationship');
        assert(
            retrieved_player.player == retrieved_inventory.player, 'Player-inventory relationship',
        );
        assert(
            retrieved_game.game_id == retrieved_level_items.game_id,
            'Game-level items relationship',
        );
        assert(retrieved_game.current_level == retrieved_level_items.level, 'Level consistency');

        // Verify data integrity
        assert(retrieved_player.items_collected == 8, 'Player items collected');
        assert(retrieved_inventory.health_potions == 4, 'Inventory potions');
        assert(retrieved_level_items.collected_health_potions == 4, 'Level collected potions');

        let total_collected_items = retrieved_level_items.collected_health_potions
            + retrieved_level_items.collected_survival_kits
            + retrieved_level_items.collected_books;
        assert(total_collected_items == 7, 'Total collected wrong');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_store_pattern_vs_direct_model_access() {
        let (mut world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create test data
        let test_player = Player {
            player: context.player1,
            health: 75,
            max_health: 100,
            level: 4,
            experience: 300,
            items_collected: 12,
        };

        // Test store pattern
        store.set_player(test_player);
        let store_retrieved: Player = store.get_player(context.player1);

        // Test direct model access
        world.write_model_test(@test_player);
        let direct_retrieved: Player = world.read_model(context.player1);

        // Both methods should yield same result
        assert(store_retrieved.player == direct_retrieved.player, 'Player address should match');
        assert(store_retrieved.health == direct_retrieved.health, 'Health should match');
        assert(
            store_retrieved.max_health == direct_retrieved.max_health, 'Max health should match',
        );
        assert(store_retrieved.level == direct_retrieved.level, 'Level should match');
        assert(
            store_retrieved.experience == direct_retrieved.experience, 'Experience should match',
        );
        assert(
            store_retrieved.items_collected == direct_retrieved.items_collected,
            'Items collected should match',
        );

        // Store pattern provides semantic interface over raw model operations
        assert(store_retrieved.level == 4, 'Store level wrong');
        assert(direct_retrieved.level == 4, 'Direct level wrong');
    }

    // ==================== STORE PATTERN DATA CONSISTENCY TESTS ====================

    #[test]
    #[available_gas(60000000)]
    fn test_store_data_consistency_across_updates() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Initial state
        let initial_player = Player {
            player: context.player1,
            health: 100,
            max_health: 100,
            level: 1,
            experience: 0,
            items_collected: 0,
        };
        store.set_player(initial_player);

        // Update 1: Gain experience
        let updated_player_1 = Player {
            player: context.player1,
            health: 100,
            max_health: 100,
            level: 1,
            experience: 50,
            items_collected: 3,
        };
        store.set_player(updated_player_1);

        // Update 2: Level up
        let updated_player_2 = Player {
            player: context.player1,
            health: 110,
            max_health: 110,
            level: 2,
            experience: 100,
            items_collected: 6,
        };
        store.set_player(updated_player_2);

        // Verify final state
        let final_player: Player = store.get_player(context.player1);
        assert(final_player.health == 110, 'Final health should be 110');
        assert(final_player.max_health == 110, 'Final max health should be 110');
        assert(final_player.level == 2, 'Final level should be 2');
        assert(final_player.experience == 100, 'Final experience should be 100');
        assert(final_player.items_collected == 6, 'Final items wrong');

        // Verify data consistency - experience threshold met for level 2
        assert(final_player.experience >= (final_player.level - 1) * 100, 'Experience wrong');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_store_isolation_between_entities() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Create entities for different players
        let player1 = Player {
            player: context.player1,
            health: 80,
            max_health: 100,
            level: 2,
            experience: 120,
            items_collected: 4,
        };
        let player2 = Player {
            player: context.player2,
            health: 95,
            max_health: 100,
            level: 1,
            experience: 30,
            items_collected: 1,
        };

        let inventory1 = PlayerInventory {
            player: context.player1, health_potions: 3, survival_kits: 1, books: 0, capacity: 50,
        };
        let inventory2 = PlayerInventory {
            player: context.player2, health_potions: 1, survival_kits: 0, books: 0, capacity: 50,
        };

        // Store all entities
        store.set_player(player1);
        store.set_player(player2);
        store.set_player_inventory(inventory1);
        store.set_player_inventory(inventory2);

        // Verify isolation
        let retrieved_player1: Player = store.get_player(context.player1);
        let retrieved_player2: Player = store.get_player(context.player2);
        let retrieved_inventory1: PlayerInventory = store.get_player_inventory(context.player1);
        let retrieved_inventory2: PlayerInventory = store.get_player_inventory(context.player2);

        // Player 1 data should not affect Player 2
        assert(retrieved_player1.level == 2, 'Player 1 level should be 2');
        assert(retrieved_player2.level == 1, 'Player 2 level should be 1');
        assert(retrieved_inventory1.health_potions == 3, 'Player 1 should have 3 potions');
        assert(retrieved_inventory2.health_potions == 1, 'Player 2 should have 1 potion');

        // Verify complete isolation
        assert(retrieved_player1.player != retrieved_player2.player, 'Players should be different');
        assert(
            retrieved_inventory1.player != retrieved_inventory2.player,
            'Inventories should be different',
        );
    }

    // ==================== STORE PATTERN PERFORMANCE AND EDGE CASES ====================

    #[test]
    #[available_gas(30000000)]
    fn test_store_edge_case_zero_values() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Test edge case with zero/empty values
        let zero_player = Player {
            player: context.player1,
            health: 0,
            max_health: 1,
            level: 1,
            experience: 0,
            items_collected: 0,
        };
        let empty_inventory = PlayerInventory {
            player: context.player1, health_potions: 0, survival_kits: 0, books: 0, capacity: 0,
        };

        store.set_player(zero_player);
        store.set_player_inventory(empty_inventory);

        let retrieved_player: Player = store.get_player(context.player1);
        let retrieved_inventory: PlayerInventory = store.get_player_inventory(context.player1);

        assert(retrieved_player.health == 0, 'Zero health should be stored');
        assert(retrieved_player.experience == 0, 'Zero experience wrong');
        assert(retrieved_inventory.capacity == 0, 'Zero capacity should be stored');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_store_maximum_values() {
        let (world, _systems, context) = spawn();
        let mut store: Store = StoreTrait::new(world);

        // Test with maximum reasonable values
        let max_player = Player {
            player: context.player1,
            health: 9999,
            max_health: 9999,
            level: 100,
            experience: 999999,
            items_collected: 9999,
        };
        let max_inventory = PlayerInventory {
            player: context.player1,
            health_potions: 999,
            survival_kits: 999,
            books: 999,
            capacity: 3000,
        };

        store.set_player(max_player);
        store.set_player_inventory(max_inventory);

        let retrieved_player: Player = store.get_player(context.player1);
        let retrieved_inventory: PlayerInventory = store.get_player_inventory(context.player1);

        assert(retrieved_player.health == 9999, 'Max health should be stored');
        assert(retrieved_player.experience == 999999, 'Max experience should be stored');
        assert(retrieved_inventory.capacity == 3000, 'Max capacity should be stored');
    }
}
