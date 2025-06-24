#[cfg(test)]
mod tests {
    use super::super::setup::{spawn, create_test_game, start_test_level, Context, Systems};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage};
    use starknet::{ContractAddress};
    
    use elysium_descent::models::game::{Game, LevelItems};
    use elysium_descent::models::world_state::WorldItem;
    use elysium_descent::types::game_types::GameStatus;
    use elysium_descent::types::item_types::ItemType;

    #[test]
    fn test_level_1_spawns_correct_item_counts() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Verify level items were created with correct counts
        let level_items: LevelItems = world.read_model((game_id, 1));
        
        // Level 1: health_potions = 3 + 1 = 4, survival_kits = (1+1)/2 = 1, books = 1/3 = 0
        assert(level_items.total_health_potions == 4, 'Level 1 should have 4 health potions');
        assert(level_items.total_survival_kits == 1, 'Level 1 should have 1 survival kit');
        assert(level_items.total_books == 0, 'Level 1 should have 0 books');
        
        // Initially no items collected
        assert(level_items.collected_health_potions == 0, 'No health potions collected yet');
        assert(level_items.collected_survival_kits == 0, 'No survival kits collected yet');
        assert(level_items.collected_books == 0, 'No books collected yet');
    }

    #[test]
    fn test_level_5_spawns_correct_item_counts() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 5
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 5);
        
        // Verify level items for level 5
        let level_items: LevelItems = world.read_model((game_id, 5));
        
        // Level 5: health_potions = 3 + 5 = 8, survival_kits = (5+1)/2 = 3, books = 5/3 = 1
        assert(level_items.total_health_potions == 8, 'Level 5 should have 8 health potions');
        assert(level_items.total_survival_kits == 3, 'Level 5 should have 3 survival kits');
        assert(level_items.total_books == 1, 'Level 5 should have 1 book');
    }

    #[test]
    fn test_level_10_caps_at_maximum_values() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 10
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 10);
        
        // Verify level items for level 10
        let level_items: LevelItems = world.read_model((game_id, 10));
        
        // Level 10: health_potions = 3 + 10 = 13 (should cap at 10), survival_kits = (10+1)/2 = 5 (should cap at 3), books = 10/3 = 3 (should cap at 2)
        assert(level_items.total_health_potions == 10, 'Level 10 should cap at 10 health potions');
        assert(level_items.total_survival_kits == 3, 'Level 10 should cap at 3 survival kits');
        assert(level_items.total_books == 2, 'Level 10 should cap at 2 books');
    }

    #[test]
    fn test_start_level_updates_game_current_level() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 3
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 3);
        
        // Verify game current level was updated
        let game: Game = world.read_model(game_id);
        assert(game.current_level == 3, 'Game current level should be 3');
        assert(game.status == GameStatus::InProgress, 'Game should still be in progress');
    }

    #[test]
    fn test_get_level_items_returns_correct_data() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and start level 2
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 2);
        
        // Get level items using the system
        let level_items = systems.actions.get_level_items(game_id, 2);
        
        // Level 2: health_potions = 3 + 2 = 5, survival_kits = (2+1)/2 = 1, books = 2/3 = 0
        assert(level_items.total_health_potions == 5, 'Should have 5 health potions');
        assert(level_items.total_survival_kits == 1, 'Should have 1 survival kit');
        assert(level_items.total_books == 0, 'Should have 0 books');
    }

    #[test]
    #[should_panic(expected: ('Not your game', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_start_level_for_other_players_game() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game as player 1
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Try to start level as player 2 - should fail
        starknet::testing::set_contract_address(context.player2);
        systems.actions.start_level(game_id, 1);
    }

    #[test]
    fn test_multiple_levels_can_be_started_sequentially() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Start multiple levels
        systems.actions.start_level(game_id, 1);
        systems.actions.start_level(game_id, 2);
        systems.actions.start_level(game_id, 3);
        
        // Verify game current level
        let game: Game = world.read_model(game_id);
        assert(game.current_level == 3, 'Game should be at level 3');
        
        // Verify all level items were created
        let level_1_items: LevelItems = world.read_model((game_id, 1));
        let level_2_items: LevelItems = world.read_model((game_id, 2));
        let level_3_items: LevelItems = world.read_model((game_id, 3));
        
        assert(level_1_items.total_health_potions == 4, 'Level 1 should have 4 health potions');
        assert(level_2_items.total_health_potions == 5, 'Level 2 should have 5 health potions');
        assert(level_3_items.total_health_potions == 6, 'Level 3 should have 6 health potions');
    }

    #[test]
    fn test_level_0_edge_case() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game and try level 0
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 0);
        
        // Verify level items for level 0
        let level_items: LevelItems = world.read_model((game_id, 0));
        
        // Level 0: health_potions = 3 + 0 = 3, survival_kits = (0+1)/2 = 0, books = 0/3 = 0
        assert(level_items.total_health_potions == 3, 'Level 0 should have 3 health potions');
        assert(level_items.total_survival_kits == 0, 'Level 0 should have 0 survival kits');
        assert(level_items.total_books == 0, 'Level 0 should have 0 books');
    }
}