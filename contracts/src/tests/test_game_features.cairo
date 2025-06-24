/// Game Features Test Suite
///
/// Comprehensive testing of game lifecycle, level progression, and scoring mechanics.
/// Tests focus on the Game model, GameComponent, and game-related workflows.

#[cfg(test)]
mod game_features_tests {
    use starknet::testing::set_contract_address;
    use elysium_descent::systems::actions::IActionsDispatcherTrait;

    // Centralized setup imports
    use elysium_descent::tests::setup::{spawn, Player, Game, LevelItems, PlayerInventory};
    use elysium_descent::helpers::store::{Store, StoreTrait};
    use elysium_descent::types::game::GameStatus;

    // ==================== GAME LIFECYCLE TESTS ====================

    #[test]
    #[available_gas(30000000)]
    fn test_game_creation_basic() {
        let (world, systems, context) = spawn();
        let store: Store = StoreTrait::new(world);

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Verify game creation
        assert(game_id == 1, 'First game ID should be 1');

        let game: Game = store.get_game(game_id);
        assert(game.player == context.player1, 'Game player should match');
        assert(game.status == GameStatus::InProgress, 'Game status wrong');
        assert(game.current_level == 0, 'Initial level should be 0');
        assert(game.score == 0, 'Initial score should be 0');
        // Note: created_at is 0 in test environment (get_block_timestamp() returns 0)

        // Verify player initialization
        let player: Player = store.get_player(context.player1);
        assert(player.health == 100, 'Initial health should be 100');
        assert(player.max_health == 100, 'Max health should be 100');
        assert(player.level == 1, 'Player level should be 1');
        assert(player.experience == 0, 'Initial experience should be 0');
        assert(player.items_collected == 0, 'Initial items wrong');

        // Verify inventory initialization
        let inventory: PlayerInventory = store.get_player_inventory(context.player1);
        assert(inventory.health_potions == 0, 'Initial potions wrong');
        assert(inventory.survival_kits == 0, 'Initial kits wrong');
        assert(inventory.books == 0, 'Initial books should be 0');
        assert(inventory.capacity == 50, 'Initial capacity should be 50');
    }

    #[test]
    #[available_gas(30000000)]
    fn test_game_counter_increments() {
        let (world, systems, context) = spawn();
        let store: Store = StoreTrait::new(world);

        // Create multiple games and verify counter increments
        set_contract_address(context.player1);
        let game1_id = systems.actions.create_game();
        assert(game1_id == 1, 'First game ID should be 1');

        set_contract_address(context.player2);
        let game2_id = systems.actions.create_game();
        assert(game2_id == 2, 'Second game ID should be 2');

        set_contract_address(context.admin);
        let game3_id = systems.actions.create_game();
        assert(game3_id == 3, 'Third game ID should be 3');

        // Verify games belong to correct players
        let game1: Game = store.get_game(game1_id);
        let game2: Game = store.get_game(game2_id);
        let game3: Game = store.get_game(game3_id);

        assert(game1.player == context.player1, 'Game 1 player wrong');
        assert(game2.player == context.player2, 'Game 2 player wrong');
        assert(game3.player == context.admin, 'Game 3 player wrong');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_complete_game_lifecycle() {
        let (world, systems, context) = spawn();
        let store: Store = StoreTrait::new(world);

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Test game creation
        let game: Game = store.get_game(game_id);
        assert(game.player == context.player1, 'Game player wrong');
        assert(game.status == GameStatus::InProgress, 'Game status wrong');
        assert(game.current_level == 0, 'Initial level wrong');
        assert(game.score == 0, 'Initial score wrong');

        // Test level progression
        systems.actions.start_level(game_id, 1);
        let updated_game: Game = store.get_game(game_id);
        assert(updated_game.current_level == 1, 'Level not updated');

        systems.actions.start_level(game_id, 5);
        let level5_game: Game = store.get_game(game_id);
        assert(level5_game.current_level == 5, 'Level 5 not set');

        // Verify level items are created properly
        let level1_items: LevelItems = store.get_level_items(game_id, 1);
        assert(level1_items.game_id == game_id, 'Level 1 game ID wrong');
        assert(level1_items.level == 1, 'Level 1 level wrong');

        let level5_items: LevelItems = store.get_level_items(game_id, 5);
        assert(level5_items.game_id == game_id, 'Level 5 game ID wrong');
        assert(level5_items.level == 5, 'Level 5 level wrong');
    }

    // ==================== LEVEL PROGRESSION TESTS ====================

    #[test]
    #[available_gas(1000000000)]
    fn test_level_progression_mechanics() {
        let (world, systems, context) = spawn();
        let store: Store = StoreTrait::new(world);

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Test level 0 (edge case)
        systems.actions.start_level(game_id, 0);
        let level0_items: LevelItems = store.get_level_items(game_id, 0);
        assert(level0_items.total_health_potions == 3, 'L0 potions wrong');
        assert(level0_items.total_survival_kits == 0, 'L0 kits wrong');
        assert(level0_items.total_books == 0, 'L0 books wrong');

        // Test level 1 calculations
        systems.actions.start_level(game_id, 1);
        let level1_items: LevelItems = store.get_level_items(game_id, 1);
        assert(level1_items.total_health_potions == 4, 'L1 potions wrong');
        assert(level1_items.total_survival_kits == 1, 'L1 kits wrong');
        assert(level1_items.total_books == 0, 'L1 books wrong');

        // Test level 3 calculations
        systems.actions.start_level(game_id, 3);
        let level3_items: LevelItems = store.get_level_items(game_id, 3);
        assert(level3_items.total_health_potions == 6, 'L3 potions wrong');
        assert(level3_items.total_survival_kits == 2, 'L3 kits wrong');
        assert(level3_items.total_books == 1, 'L3 books wrong');

        // Test level 6 calculations
        systems.actions.start_level(game_id, 6);
        let level6_items: LevelItems = store.get_level_items(game_id, 6);
        assert(level6_items.total_health_potions == 9, 'L6 potions wrong');
        assert(level6_items.total_survival_kits == 3, 'L6 kits wrong');
        assert(level6_items.total_books == 2, 'L6 books wrong');

        // Test maximum limits at high levels
        systems.actions.start_level(game_id, 15);
        let level15_items: LevelItems = store.get_level_items(game_id, 15);
        assert(level15_items.total_health_potions == 10, 'Max potions wrong');
        assert(level15_items.total_survival_kits == 3, 'Max kits wrong');
        assert(level15_items.total_books == 2, 'Max books wrong');

        // Test very high level (boundary test)
        systems.actions.start_level(game_id, 100);
        let level100_items: LevelItems = store.get_level_items(game_id, 100);
        assert(level100_items.total_health_potions == 10, 'L100 max potions wrong');
        assert(level100_items.total_survival_kits == 3, 'L100 max kits wrong');
        assert(level100_items.total_books == 2, 'L100 max books wrong');
    }

    #[test]
    #[available_gas(300000000)]
    fn test_level_items_initialization() {
        let (world, systems, context) = spawn();
        let store: Store = StoreTrait::new(world);

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();
        systems.actions.start_level(game_id, 3);

        let level_items: LevelItems = store.get_level_items(game_id, 3);

        // Verify all fields are properly initialized
        assert(level_items.game_id == game_id, 'Game ID mismatch');
        assert(level_items.level == 3, 'Level mismatch');
        assert(level_items.total_health_potions > 0, 'Should have health potions');
        assert(level_items.total_survival_kits >= 0, 'Survival kits valid range');
        assert(level_items.total_books >= 0, 'Books valid range');

        // Verify collected counts start at zero
        assert(level_items.collected_health_potions == 0, 'Collected potions wrong');
        assert(level_items.collected_survival_kits == 0, 'Collected kits wrong');
        assert(level_items.collected_books == 0, 'Collected books wrong');
    }

    // ==================== GAME OWNERSHIP AND SECURITY TESTS ====================

    #[test]
    #[available_gas(30000000)]
    fn test_game_ownership_security() {
        let (world, systems, context) = spawn();
        let store: Store = StoreTrait::new(world);

        // Player 1 creates a game
        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Verify ownership
        let game: Game = store.get_game(game_id);
        assert(game.player == context.player1, 'Game owner should be player1');
        assert(game.player != context.player2, 'Wrong player access');

        // Player 2 creates their own game
        set_contract_address(context.player2);
        let player2_game_id = systems.actions.create_game();
        assert(player2_game_id == 2, 'Player2 game ID should be 2');

        let player2_game: Game = store.get_game(player2_game_id);
        assert(player2_game.player == context.player2, 'Game 2 owner should be player2');
        assert(player2_game.player != context.player1, 'Wrong player access');

        // Verify games are completely separate
        assert(game_id != player2_game_id, 'Game IDs should be different');
    }

    #[test]
    #[available_gas(60000000)]
    fn test_multi_player_game_isolation() {
        let (world, systems, context) = spawn();
        let store: Store = StoreTrait::new(world);

        // Player 1 creates game and progresses to level 1
        set_contract_address(context.player1);
        let game1_id = systems.actions.create_game();
        systems.actions.start_level(game1_id, 1);

        // Player 2 creates game and progresses to level 2
        set_contract_address(context.player2);
        let game2_id = systems.actions.create_game();
        systems.actions.start_level(game2_id, 2);

        // Verify games are separate
        assert(game1_id != game2_id, 'Games should have different IDs');

        let game1: Game = store.get_game(game1_id);
        let game2: Game = store.get_game(game2_id);

        assert(game1.player == context.player1, 'Game 1 owner wrong');
        assert(game2.player == context.player2, 'Game 2 owner wrong');
        assert(game1.current_level == 1, 'Game 1 level wrong');
        assert(game2.current_level == 2, 'Game 2 level wrong');

        // Verify player stats are separate
        let player1_stats: Player = store.get_player(context.player1);
        let player2_stats: Player = store.get_player(context.player2);

        assert(player1_stats.player == context.player1, 'Player 1 stats wrong');
        assert(player2_stats.player == context.player2, 'Player 2 stats wrong');

        // Verify level items are separate
        let level1_items: LevelItems = store.get_level_items(game1_id, 1);
        let level2_items: LevelItems = store.get_level_items(game2_id, 2);

        assert(level1_items.game_id == game1_id, 'Level 1 items wrong game');
        assert(level2_items.game_id == game2_id, 'Level 2 items wrong game');
        assert(level1_items.level == 1, 'Level 1 items wrong level');
        assert(level2_items.level == 2, 'Level 2 items wrong level');
    }

    // ==================== EDGE CASES AND BOUNDARY CONDITIONS ====================

    #[test]
    #[available_gas(60000000)]
    fn test_edge_cases_and_boundary_conditions() {
        let (world, systems, context) = spawn();
        let store: Store = StoreTrait::new(world);

        set_contract_address(context.player1);
        let game_id = systems.actions.create_game();

        // Test starting level 0 (edge case)
        systems.actions.start_level(game_id, 0);
        let level0_items: LevelItems = store.get_level_items(game_id, 0);
        assert(level0_items.total_health_potions == 3, 'L0 potions wrong');
        assert(level0_items.total_survival_kits == 0, 'L0 kits wrong');
        assert(level0_items.total_books == 0, 'L0 books wrong');

        // Test very high level (boundary test)
        systems.actions.start_level(game_id, 100);
        let level100_items: LevelItems = store.get_level_items(game_id, 100);
        assert(level100_items.total_health_potions == 10, 'L100 max potions wrong');
        assert(level100_items.total_survival_kits == 3, 'L100 max kits wrong');
        assert(level100_items.total_books == 2, 'L100 max books wrong');

        // Test game counter consistency with multiple rapid game creations
        set_contract_address(context.player2);
        let game2_id = systems.actions.create_game();
        assert(game2_id == 2, 'Game 2 ID wrong');

        set_contract_address(context.admin);
        let game3_id = systems.actions.create_game();
        assert(game3_id == 3, 'Game 3 ID wrong');

        // Verify counter increments properly
        assert(game3_id > game2_id, 'Game IDs should increment');
        assert(game2_id > game_id, 'Game IDs should increment');
    }
}
