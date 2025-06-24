// Main test orchestrator for Elysium Descent
// This file serves as the entry point for all tests

// The individual test files are imported at the lib.cairo level
// This file contains integration tests that verify the overall system

#[cfg(test)]
mod integration_tests {
    use starknet::testing::set_contract_address;
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    // Use centralized setup instead of duplicating 40+ lines!
    use elysium_descent::tests::setup::{
        spawn, 
        Player, Game, LevelItems, GameCounter, PlayerInventory, WorldItem
    };

    #[test]
    fn test_world_setup_works() {
        // Use centralized setup - no duplication!
        let (world, systems, context) = spawn();

        // Verify we can create a game
        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        assert(game_id == 1, 'First game ID should be 1');

        // Verify game was created
        let game: Game = world.read_model(game_id);
        assert(game.player == context.player1, 'Game player should match');
    }

    #[test]
    fn test_multiple_players_isolated() {
        // Use centralized setup - clean and simple!
        let (world, systems, context) = spawn();

        // Player 1 creates game
        set_contract_address(context.player1);
        let game_id_1 = systems.actions.create_game();

        // Player 2 creates game
        set_contract_address(context.player2);
        let game_id_2 = systems.actions.create_game();

        // Verify games are independent
        assert(game_id_1 != game_id_2, 'Game IDs should be different');

        let game_1: Game = world.read_model(game_id_1);
        let game_2: Game = world.read_model(game_id_2);

        assert(game_1.player == context.player1, 'Game 1 belongs to player 1');
        assert(game_2.player == context.player2, 'Game 2 belongs to player 2');

        // Test additional models to use the imported types
        test_additional_models(world, context.player1);
    }

    // Helper function to test additional model types that were imported
    fn test_additional_models(mut world: WorldStorage, player: starknet::ContractAddress) {
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
            player,
            health: 80,
            max_health: 100,
            level: 2,
            experience: 150,
            items_collected: 3,
        };
        world.write_model_test(@player_model);
        let read_player: Player = world.read_model(player);
        assert(read_player.level == 2, 'Player level should be 2');

        // Test PlayerInventory model
        let inventory = PlayerInventory {
            player, health_potions: 3, survival_kits: 1, books: 1, capacity: 15,
        };
        world.write_model_test(@inventory);
        let read_inventory: PlayerInventory = world.read_model(player);
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


