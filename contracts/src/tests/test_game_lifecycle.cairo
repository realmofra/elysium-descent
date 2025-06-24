#[cfg(test)]
mod tests {
    use super::super::setup::{spawn, create_test_game, Context, Systems};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::{ModelStorage};
    use starknet::{ContractAddress, get_block_timestamp};
    
    use elysium_descent::models::player::Player;
    use elysium_descent::models::game::{Game, GameCounter, GAME_COUNTER_ID};
    use elysium_descent::models::inventory::PlayerInventory;
    use elysium_descent::types::game_types::GameStatus;

    #[test]
    fn test_create_game_initializes_player_correctly() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game as player
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Verify game was created with correct values
        let game: Game = world.read_model(game_id);
        assert(game.game_id == 1, 'Game ID should be 1');
        assert(game.player == context.player, 'Game player should match');
        assert(game.status == GameStatus::InProgress, 'Game should be in progress');
        assert(game.current_level == 0, 'Game level should start at 0');
        assert(game.score == 0, 'Game score should start at 0');
        
        // Verify player stats were initialized correctly  
        let player_stats: Player = world.read_model(context.player);
        assert(player_stats.player == context.player, 'Player address should match');
        assert(player_stats.health == 100, 'Player health should be 100');
        assert(player_stats.max_health == 100, 'Player max health should be 100');
        assert(player_stats.level == 1, 'Player level should be 1');
        assert(player_stats.experience == 0, 'Player experience should be 0');
        assert(player_stats.items_collected == 0, 'Items collected should be 0');
    }

    #[test]
    fn test_create_game_initializes_inventory_correctly() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game as player
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Verify inventory was initialized correctly
        let inventory: PlayerInventory = world.read_model(context.player);
        assert(inventory.player == context.player, 'Inventory player should match');
        assert(inventory.health_potions == 0, 'Health potions should be 0');
        assert(inventory.survival_kits == 0, 'Survival kits should be 0');
        assert(inventory.books == 0, 'Books should be 0');
        assert(inventory.capacity == 50, 'Inventory capacity should be 50');
    }

    #[test]
    fn test_game_ids_are_unique_and_sequential() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create first game as player 1
        starknet::testing::set_contract_address(context.player);
        let game_id_1 = systems.actions.create_game();
        
        // Create second game as player 2
        starknet::testing::set_contract_address(context.player2);
        let game_id_2 = systems.actions.create_game();
        
        // Verify game IDs are sequential
        assert(game_id_1 == 1, 'First game ID should be 1');
        assert(game_id_2 == 2, 'Second game ID should be 2');
        assert(game_id_1 != game_id_2, 'Game IDs should be different');
        
        // Verify game counter was updated correctly
        let counter: GameCounter = world.read_model(GAME_COUNTER_ID);
        assert(counter.next_game_id == 3, 'Next game ID should be 3');
    }

    #[test]
    fn test_multiple_players_can_create_games() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game as player 1
        starknet::testing::set_contract_address(context.player);
        let game_id_1 = systems.actions.create_game();
        
        // Create game as player 2
        starknet::testing::set_contract_address(context.player2);
        let game_id_2 = systems.actions.create_game();
        
        // Verify both games exist and have correct owners
        let game_1: Game = world.read_model(game_id_1);
        let game_2: Game = world.read_model(game_id_2);
        
        assert(game_1.player == context.player, 'Game 1 should belong to player 1');
        assert(game_2.player == context.player2, 'Game 2 should belong to player 2');
        assert(game_1.status == GameStatus::InProgress, 'Game 1 should be in progress');
        assert(game_2.status == GameStatus::InProgress, 'Game 2 should be in progress');
        
        // Verify both players have stats initialized
        let player_1_stats: Player = world.read_model(context.player);
        let player_2_stats: Player = world.read_model(context.player2);
        
        assert(player_1_stats.health == 100, 'Player 1 health should be 100');
        assert(player_2_stats.health == 100, 'Player 2 health should be 100');
    }

    #[test] 
    fn test_get_player_stats_returns_correct_data() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game as player
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Get player stats using the system
        let player_stats = systems.actions.get_player_stats(context.player);
        
        // Verify stats match what we expect
        assert(player_stats.player == context.player, 'Player address should match');
        assert(player_stats.health == 100, 'Health should be 100');
        assert(player_stats.max_health == 100, 'Max health should be 100');
        assert(player_stats.level == 1, 'Level should be 1');
        assert(player_stats.experience == 0, 'Experience should be 0');
        assert(player_stats.items_collected == 0, 'Items collected should be 0');
    }

    #[test]
    fn test_get_player_inventory_returns_correct_data() {
        // Setup test world
        let (world, systems, context) = spawn();
        
        // Create game as player
        starknet::testing::set_contract_address(context.player);
        let game_id = systems.actions.create_game();
        
        // Get player inventory using the system
        let inventory = systems.actions.get_player_inventory(context.player);
        
        // Verify inventory matches what we expect
        assert(inventory.player == context.player, 'Inventory player should match');
        assert(inventory.health_potions == 0, 'Health potions should be 0');
        assert(inventory.survival_kits == 0, 'Survival kits should be 0');
        assert(inventory.books == 0, 'Books should be 0');
        assert(inventory.capacity == 50, 'Capacity should be 50');
    }
}