#[cfg(test)]
mod tests {
    use super::super::setup::{spawn, create_test_game, start_test_level, Context, Systems};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage};
    use starknet::{ContractAddress};
    
    use elysium_descent::models::player::Player;
    use elysium_descent::models::inventory::PlayerInventory;
    use elysium_descent::models::game::{Game, LevelItems};
    use elysium_descent::models::world_state::WorldItem;
    use elysium_descent::types::game_types::GameStatus;
    use elysium_descent::types::item_types::ItemType;

    // Helper function to create a world item for testing
    fn create_test_world_item(world: WorldStorage, game_id: u32, item_id: u32, item_type: ItemType, level: u32) {
        let world_item = WorldItem {
            game_id,
            item_id,
            item_type,
            x_position: 50,
            y_position: 50,
            is_collected: false,
            level,
        };
        world.write_model(@world_item);
    }

    #[test]
    fn test_complete_level_1_workflow() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Step 1: Create game
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Verify initial state
        let initial_player: Player = world.read_model(context.player);
        let initial_inventory: PlayerInventory = world.read_model(context.player);
        assert(initial_player.health == 100, 'Initial health should be 100');
        assert(initial_inventory.health_potions == 0, 'Initial inventory should be empty');
        
        // Step 2: Start level 1
        systems.actions.start_level(game_id, 1);
        
        // Verify level was started correctly
        let game: Game = world.read_model(game_id);
        let level_items: LevelItems = world.read_model((game_id, 1));
        assert(game.current_level == 1, 'Game should be at level 1');
        assert(level_items.total_health_potions == 4, 'Level 1 should have 4 health potions');
        assert(level_items.total_survival_kits == 1, 'Level 1 should have 1 survival kit');
        assert(level_items.total_books == 0, 'Level 1 should have 0 books');
        
        // Step 3: Create and collect all items for level 1
        // Create 4 health potions
        create_test_world_item(world, game_id, 1001, ItemType::HealthPotion, 1);
        create_test_world_item(world, game_id, 1002, ItemType::HealthPotion, 1);
        create_test_world_item(world, game_id, 1003, ItemType::HealthPotion, 1);
        create_test_world_item(world, game_id, 1004, ItemType::HealthPotion, 1);
        
        // Create 1 survival kit
        create_test_world_item(world, game_id, 1005, ItemType::SurvivalKit, 1);
        
        // Collect all items
        systems.actions.pickup_item(game_id, 1001);
        systems.actions.pickup_item(game_id, 1002);
        systems.actions.pickup_item(game_id, 1003);
        systems.actions.pickup_item(game_id, 1004);
        systems.actions.pickup_item(game_id, 1005);
        
        // Step 4: Verify final state
        let final_player: Player = world.read_model(context.player);
        let final_inventory: PlayerInventory = world.read_model(context.player);
        let final_level_items: LevelItems = world.read_model((game_id, 1));
        
        // Verify player progression
        assert(final_player.items_collected == 5, 'Should have collected 5 items');
        assert(final_player.experience > initial_player.experience, 'Experience should have increased');
        
        // Verify inventory updates
        assert(final_inventory.health_potions == 4, 'Should have 4 health potions');
        assert(final_inventory.survival_kits == 1, 'Should have 1 survival kit');
        assert(final_inventory.books == 0, 'Should have 0 books');
        
        // Verify level completion tracking
        assert(final_level_items.collected_health_potions == 4, 'Should have collected 4 health potions');
        assert(final_level_items.collected_survival_kits == 1, 'Should have collected 1 survival kit');
        assert(final_level_items.collected_books == 0, 'Should have collected 0 books');
    }

    #[test]
    fn test_multiple_level_progression() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Progress through multiple levels
        for level in 1_u32..4_u32 {
            // Start level
            systems.actions.start_level(game_id, level);
            
            // Verify level items were created correctly
            let level_items: LevelItems = world.read_model((game_id, level));
            let expected_health_potions = 3 + level;
            let expected_survival_kits = (level + 1) / 2;
            let expected_books = level / 3;
            
            assert(level_items.total_health_potions == expected_health_potions, 'Health potions count incorrect');
            assert(level_items.total_survival_kits == expected_survival_kits, 'Survival kits count incorrect');
            assert(level_items.total_books == expected_books, 'Books count incorrect');
            
            // Create and collect some items (not all, just a few for testing)
            let item_id_base = level * 1000;
            create_test_world_item(world, game_id, item_id_base + 1, ItemType::HealthPotion, level);
            create_test_world_item(world, game_id, item_id_base + 2, ItemType::HealthPotion, level);
            
            systems.actions.pickup_item(game_id, item_id_base + 1);
            systems.actions.pickup_item(game_id, item_id_base + 2);
        }
        
        // Verify final game state
        let final_game: Game = world.read_model(game_id);
        let final_player: Player = world.read_model(context.player);
        let final_inventory: PlayerInventory = world.read_model(context.player);
        
        assert(final_game.current_level == 3, 'Game should be at level 3');
        assert(final_player.items_collected == 6, 'Should have collected 6 items total (2 per level)');
        assert(final_inventory.health_potions == 6, 'Should have 6 health potions');
    }

    #[test]
    fn test_concurrent_player_workflows() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Player 1 workflow
        starknet::testing::set_contract_address(context.player);
        let game_id_1 = systems.actions.create_game();
        systems.actions.start_level(game_id_1, 1);
        
        // Player 2 workflow  
        starknet::testing::set_contract_address(context.player2);
        let game_id_2 = systems.actions.create_game();
        systems.actions.start_level(game_id_2, 2);
        
        // Create items for both games
        create_test_world_item(world, game_id_1, 1001, ItemType::HealthPotion, 1);
        create_test_world_item(world, game_id_1, 1002, ItemType::SurvivalKit, 1);
        
        create_test_world_item(world, game_id_2, 2001, ItemType::HealthPotion, 2);
        create_test_world_item(world, game_id_2, 2002, ItemType::Book, 2);
        
        // Players collect items from their respective games
        starknet::testing::set_contract_address(context.player);
        systems.actions.pickup_item(game_id_1, 1001);
        systems.actions.pickup_item(game_id_1, 1002);
        
        starknet::testing::set_contract_address(context.player2);
        systems.actions.pickup_item(game_id_2, 2001);
        systems.actions.pickup_item(game_id_2, 2002);
        
        // Verify both players have independent progress
        let player_1_stats = systems.actions.get_player_stats(context.player);
        let player_1_inventory = systems.actions.get_player_inventory(context.player);
        
        let player_2_stats = systems.actions.get_player_stats(context.player2);
        let player_2_inventory = systems.actions.get_player_inventory(context.player2);
        
        // Player 1 verification
        assert(player_1_stats.items_collected == 2, 'Player 1 should have collected 2 items');
        assert(player_1_inventory.health_potions == 1, 'Player 1 should have 1 health potion');
        assert(player_1_inventory.survival_kits == 1, 'Player 1 should have 1 survival kit');
        assert(player_1_inventory.books == 0, 'Player 1 should have 0 books');
        
        // Player 2 verification
        assert(player_2_stats.items_collected == 2, 'Player 2 should have collected 2 items');
        assert(player_2_inventory.health_potions == 1, 'Player 2 should have 1 health potion');
        assert(player_2_inventory.survival_kits == 0, 'Player 2 should have 0 survival kits');
        assert(player_2_inventory.books == 1, 'Player 2 should have 1 book');
        
        // Verify games are independent
        let game_1: Game = world.read_model(game_id_1);
        let game_2: Game = world.read_model(game_id_2);
        
        assert(game_1.current_level == 1, 'Game 1 should be at level 1');
        assert(game_2.current_level == 2, 'Game 2 should be at level 2');
    }

    #[test]
    fn test_full_game_session_with_experience_progression() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        let mut total_items_collected = 0_u32;
        let mut total_health_potions = 0_u32;
        let mut total_survival_kits = 0_u32;
        let mut total_books = 0_u32;
        
        // Play through first 3 levels
        for level in 1_u32..4_u32 {
            systems.actions.start_level(game_id, level);
            
            // Get level configuration
            let level_items: LevelItems = world.read_model((game_id, level));
            
            // Create all items for this level
            let mut item_counter = 0_u32;
            
            // Create health potions
            let mut i = 0_u32;
            loop {
                if i >= level_items.total_health_potions {
                    break;
                }
                let item_id = level * 10000 + item_counter;
                create_test_world_item(world, game_id, item_id, ItemType::HealthPotion, level);
                systems.actions.pickup_item(game_id, item_id);
                item_counter += 1;
                i += 1;
            };
            
            // Create survival kits
            let mut i = 0_u32;
            loop {
                if i >= level_items.total_survival_kits {
                    break;
                }
                let item_id = level * 10000 + item_counter;
                create_test_world_item(world, game_id, item_id, ItemType::SurvivalKit, level);
                systems.actions.pickup_item(game_id, item_id);
                item_counter += 1;
                i += 1;
            };
            
            // Create books
            let mut i = 0_u32;
            loop {
                if i >= level_items.total_books {
                    break;
                }
                let item_id = level * 10000 + item_counter;
                create_test_world_item(world, game_id, item_id, ItemType::Book, level);
                systems.actions.pickup_item(game_id, item_id);
                item_counter += 1;
                i += 1;
            };
            
            // Track totals
            total_items_collected += level_items.total_health_potions + level_items.total_survival_kits + level_items.total_books;
            total_health_potions += level_items.total_health_potions;
            total_survival_kits += level_items.total_survival_kits;
            total_books += level_items.total_books;
        }
        
        // Verify final game state
        let final_player: Player = world.read_model(context.player);
        let final_inventory: PlayerInventory = world.read_model(context.player);
        let final_game: Game = world.read_model(game_id);
        
        assert(final_game.current_level == 3, 'Game should be at level 3');
        assert(final_player.items_collected == total_items_collected, 'Total items collected should match');
        assert(final_inventory.health_potions == total_health_potions, 'Total health potions should match');
        assert(final_inventory.survival_kits == total_survival_kits, 'Total survival kits should match');
        assert(final_inventory.books == total_books, 'Total books should match');
        
        // Verify experience progression
        assert(final_player.experience > 0, 'Player should have gained experience');
        
        // Expected totals based on level formulas:
        // Level 1: 4 health potions + 1 survival kit + 0 books = 5 items
        // Level 2: 5 health potions + 1 survival kit + 0 books = 6 items  
        // Level 3: 6 health potions + 2 survival kits + 1 book = 9 items
        // Total: 20 items, 15 health potions, 4 survival kits, 1 book
        assert(total_items_collected == 20, 'Should have collected 20 items total');
        assert(total_health_potions == 15, 'Should have 15 health potions total');
        assert(total_survival_kits == 4, 'Should have 4 survival kits total');
        assert(total_books == 1, 'Should have 1 book total');
    }
}