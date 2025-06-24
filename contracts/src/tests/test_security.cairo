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

    // Helper function to create a world item for testing
    fn create_test_world_item(world: WorldStorage, game_id: u32, item_id: u32, item_type: ItemType) {
        let world_item = WorldItem {
            game_id,
            item_id,
            item_type,
            x_position: 50,
            y_position: 50,
            is_collected: false,
            level: 1,
        };
        world.write_model(@world_item);
    }

    #[test]
    #[should_panic(expected: ('Not your game', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_pickup_items_from_other_players_game() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Player 1 creates game and starts level
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 1);
        
        // Create a test world item in player 1's game
        let item_id = 12345_u32;
        create_test_world_item(world, game_id, item_id, ItemType::HealthPotion);
        
        // Player 2 tries to pickup item from player 1's game - should fail
        starknet::testing::set_contract_address(context.player2);
        systems.actions.pickup_item(game_id, item_id);
    }

    #[test]
    #[should_panic(expected: ('Not your game', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_start_level_for_other_players_game() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Player 1 creates game
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Player 2 tries to start level for player 1's game - should fail
        starknet::testing::set_contract_address(context.player2);
        systems.actions.start_level(game_id, 1);
    }

    #[test]
    #[should_panic(expected: ('Game not found', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_pickup_item_from_nonexistent_game() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Try to pickup item from game that doesn't exist
        starknet::testing::set_contract_address(context.player);
        let nonexistent_game_id = 99999_u32;
        let item_id = 12345_u32;
        systems.actions.pickup_item(nonexistent_game_id, item_id);
    }

    #[test]
    #[should_panic(expected: ('Game not found', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_start_level_for_nonexistent_game() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Try to start level for game that doesn't exist
        starknet::testing::set_contract_address(context.player);
        let nonexistent_game_id = 99999_u32;
        systems.actions.start_level(nonexistent_game_id, 1);
    }

    #[test]
    #[should_panic(expected: ('Item does not exist', 'ENTRYPOINT_FAILED'))]
    fn test_cannot_pickup_item_from_wrong_game() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Player 1 creates game 1
        starknet::testing::set_contract_address(context.player);
        let game_id_1 = systems.actions.create_game();
        systems.actions.start_level(game_id_1, 1);
        
        // Player 2 creates game 2
        starknet::testing::set_contract_address(context.player2);
        let game_id_2 = systems.actions.create_game();
        systems.actions.start_level(game_id_2, 1);
        
        // Create item in game 1
        let item_id = 12345_u32;
        create_test_world_item(world, game_id_1, item_id, ItemType::HealthPotion);
        
        // Player 2 tries to pickup item from game 1 using their own game ID - should fail
        starknet::testing::set_contract_address(context.player2);
        systems.actions.pickup_item(game_id_2, item_id); // Item exists in game_id_1, not game_id_2
    }

    #[test]
    fn test_players_can_access_their_own_games_independently() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Player 1 creates and operates their game
        starknet::testing::set_contract_address(context.player);
        let game_id_1 = systems.actions.create_game();
        systems.actions.start_level(game_id_1, 1);
        
        // Player 2 creates and operates their game
        starknet::testing::set_contract_address(context.player2);
        let game_id_2 = systems.actions.create_game();
        systems.actions.start_level(game_id_2, 2);
        
        // Verify both games exist independently
        let game_1: Game = world.read_model(game_id_1);
        let game_2: Game = world.read_model(game_id_2);
        
        assert(game_1.player == context.player, 'Game 1 should belong to player 1');
        assert(game_2.player == context.player2, 'Game 2 should belong to player 2');
        assert(game_1.current_level == 1, 'Game 1 should be at level 1');
        assert(game_2.current_level == 2, 'Game 2 should be at level 2');
        
        // Create items in both games
        create_test_world_item(world, game_id_1, 1001, ItemType::HealthPotion);
        create_test_world_item(world, game_id_2, 2001, ItemType::SurvivalKit);
        
        // Each player can pickup from their own game
        starknet::testing::set_contract_address(context.player);
        let pickup_1 = systems.actions.pickup_item(game_id_1, 1001);
        assert(pickup_1, 'Player 1 should pickup from their game');
        
        starknet::testing::set_contract_address(context.player2);
        let pickup_2 = systems.actions.pickup_item(game_id_2, 2001);
        assert(pickup_2, 'Player 2 should pickup from their game');
    }

    #[test]
    fn test_get_player_stats_returns_zero_for_uninitialized_player() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Try to get stats for player who hasn't created a game yet
        let player_stats = systems.actions.get_player_stats(context.player);
        
        // Should return default/zero values
        assert(player_stats.player == context.player, 'Player address should match');
        assert(player_stats.health == 0, 'Uninitialized health should be 0');
        assert(player_stats.max_health == 0, 'Uninitialized max health should be 0');
        assert(player_stats.level == 0, 'Uninitialized level should be 0');
        assert(player_stats.experience == 0, 'Uninitialized experience should be 0');
        assert(player_stats.items_collected == 0, 'Uninitialized items collected should be 0');
    }

    #[test]
    fn test_get_player_inventory_returns_zero_for_uninitialized_player() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Try to get inventory for player who hasn't created a game yet
        let inventory = systems.actions.get_player_inventory(context.player);
        
        // Should return default/zero values
        assert(inventory.player == context.player, 'Player address should match');
        assert(inventory.health_potions == 0, 'Uninitialized health potions should be 0');
        assert(inventory.survival_kits == 0, 'Uninitialized survival kits should be 0');
        assert(inventory.books == 0, 'Uninitialized books should be 0');
        assert(inventory.capacity == 0, 'Uninitialized capacity should be 0');
    }

    #[test]
    fn test_get_level_items_returns_zero_for_nonexistent_level() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game but don't start any levels
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Try to get level items for level that doesn't exist
        let level_items = systems.actions.get_level_items(game_id, 1);
        
        // Should return default/zero values
        assert(level_items.game_id == game_id, 'Game ID should match');
        assert(level_items.level == 1, 'Level should match');
        assert(level_items.total_health_potions == 0, 'Total health potions should be 0');
        assert(level_items.total_survival_kits == 0, 'Total survival kits should be 0');
        assert(level_items.total_books == 0, 'Total books should be 0');
    }

    #[test]
    fn test_game_isolation_between_players() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Player 1 creates game and picks up items
        starknet::testing::set_contract_address(context.player);
        let game_id_1 = systems.actions.create_game();
        systems.actions.start_level(game_id_1, 1);
        
        create_test_world_item(world, game_id_1, 1001, ItemType::HealthPotion);
        systems.actions.pickup_item(game_id_1, 1001);
        
        // Player 2 creates game
        starknet::testing::set_contract_address(context.player2);
        let game_id_2 = systems.actions.create_game();
        
        // Verify player 1's actions don't affect player 2's stats
        let player_1_stats = systems.actions.get_player_stats(context.player);
        let player_2_stats = systems.actions.get_player_stats(context.player2);
        
        assert(player_1_stats.items_collected == 1, 'Player 1 should have 1 item collected');
        assert(player_2_stats.items_collected == 0, 'Player 2 should have 0 items collected');
        
        let player_1_inventory = systems.actions.get_player_inventory(context.player);
        let player_2_inventory = systems.actions.get_player_inventory(context.player2);
        
        assert(player_1_inventory.health_potions == 1, 'Player 1 should have 1 health potion');
        assert(player_2_inventory.health_potions == 0, 'Player 2 should have 0 health potions');
    }
}