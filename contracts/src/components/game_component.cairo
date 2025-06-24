use starknet::ContractAddress;
use core::poseidon::poseidon_hash_span;
use elysium_descent::helpers::store::{Store, StoreTrait};
use elysium_descent::models::game::{Game, LevelItems, GameCounter, GAME_COUNTER_ID};
use elysium_descent::models::player::Player;
use elysium_descent::models::inventory::PlayerInventory;
use elysium_descent::models::world_state::WorldItem;
use elysium_descent::types::game_types::GameStatus;
use elysium_descent::types::item_types::ItemType;

/// Game Component - handles game lifecycle and level management
#[generate_trait]
pub impl GameComponentImpl of GameComponentTrait {
    /// Creates a new game instance for the specified player
    fn create_game(ref store: Store, player: ContractAddress, timestamp: u64) -> u32 {
        // Generate unique game ID using singleton counter
        let mut counter: GameCounter = store.get_game_counter();
        if counter.next_game_id == 0 {
            let new_counter = GameCounter { counter_id: GAME_COUNTER_ID, next_game_id: 1 };
            store.set_game_counter(new_counter);
            counter = new_counter;
        }

        let game_id = counter.next_game_id;
        let updated_counter = GameCounter {
            counter_id: GAME_COUNTER_ID, next_game_id: counter.next_game_id + 1,
        };
        store.set_game_counter(updated_counter);

        // Initialize new game instance with default values
        let game = Game {
            game_id,
            player,
            status: GameStatus::InProgress,
            current_level: 0,
            created_at: timestamp,
            score: 0,
        };
        store.set_game(game);

        // Create initial player stats with default values
        let player_stats = Player {
            player, health: 100, max_health: 100, level: 1, experience: 0, items_collected: 0,
        };
        store.set_player(player_stats);

        // Create empty player inventory with default capacity
        let inventory = PlayerInventory {
            player, health_potions: 0, survival_kits: 0, books: 0, capacity: 50,
        };
        store.set_player_inventory(inventory);

        // Emit game creation event for external systems
        store.emit_game_created(player, game_id, timestamp);

        game_id
    }
    fn start_level(ref store: Store, player: ContractAddress, game_id: u32, level: u32) -> u32 {
        // Validate game ownership and active status
        let mut game = store.get_game(game_id);
        assert(game.player == player, 'Not your game');
        assert(game.status == GameStatus::InProgress, 'Game not in progress');

        // Update game state to reflect current level
        let updated_game = Game {
            game_id: game.game_id,
            player: game.player,
            status: game.status,
            current_level: level,
            created_at: game.created_at,
            score: game.score,
        };
        store.set_game(updated_game);

        // Determine item spawn counts based on level progression
        let health_potions_count = Self::calculate_level_health_potions(level);
        let survival_kits_count = Self::calculate_level_survival_kits(level);
        let books_count = Self::calculate_level_books(level);

        // Initialize level tracking model for collection progress
        let level_items = LevelItems {
            game_id,
            level,
            total_health_potions: health_potions_count,
            total_survival_kits: survival_kits_count,
            total_books: books_count,
            collected_health_potions: 0,
            collected_survival_kits: 0,
            collected_books: 0,
        };
        store.set_level_items(level_items);

        // Spawn physical world items for collection
        let mut item_counter = 0_u32;

        // Create health potion instances in the world
        Self::spawn_items_of_type(
            ref store,
            game_id,
            level,
            ref item_counter,
            ItemType::HealthPotion,
            health_potions_count,
        );

        // Create survival kit instances in the world
        Self::spawn_items_of_type(
            ref store, game_id, level, ref item_counter, ItemType::SurvivalKit, survival_kits_count,
        );

        // Create book instances in the world
        Self::spawn_items_of_type(
            ref store, game_id, level, ref item_counter, ItemType::Book, books_count,
        );

        let total_items = health_potions_count + survival_kits_count + books_count;
        store.emit_level_started(player, game_id, level, total_items);

        total_items
    }

    fn complete_level(ref store: Store, player: ContractAddress, game_id: u32, level: u32) -> bool {
        let game = store.get_game(game_id);
        assert(game.player == player, 'Not your game');
        assert(game.current_level == level, 'Not current level');

        let level_items = store.get_level_items(game_id, level);

        // Verify all level items have been successfully collected
        let items_completed = level_items
            .collected_health_potions == level_items
            .total_health_potions
            && level_items.collected_survival_kits == level_items.total_survival_kits
            && level_items.collected_books == level_items.total_books;

        if items_completed {
            // Grant experience bonus for completing the level
            let player_stats = store.get_player(player);
            let updated_player = Player {
                player: player_stats.player,
                health: player_stats.health,
                max_health: player_stats.max_health,
                level: player_stats.level,
                experience: player_stats.experience + 100, // Flat bonus for level completion
                items_collected: player_stats.items_collected,
            };
            store.set_player(updated_player);
        }

        items_completed
    }

    fn pause_game(ref store: Store, player: ContractAddress, game_id: u32) {
        let game = store.get_game(game_id);
        assert(game.player == player, 'Not your game');
        assert(game.status == GameStatus::InProgress, 'Game not in progress');

        let updated_game = Game {
            game_id: game.game_id,
            player: game.player,
            status: GameStatus::Paused,
            current_level: game.current_level,
            created_at: game.created_at,
            score: game.score,
        };
        store.set_game(updated_game);
    }

    fn resume_game(ref store: Store, player: ContractAddress, game_id: u32) {
        let game = store.get_game(game_id);
        assert(game.player == player, 'Not your game');
        assert(game.status == GameStatus::Paused, 'Game not paused');

        let updated_game = Game {
            game_id: game.game_id,
            player: game.player,
            status: GameStatus::InProgress,
            current_level: game.current_level,
            created_at: game.created_at,
            score: game.score,
        };
        store.set_game(updated_game);
    }

    fn end_game(ref store: Store, player: ContractAddress, game_id: u32, final_score: u32) {
        let game = store.get_game(game_id);
        assert(game.player == player, 'Not your game');

        let updated_game = Game {
            game_id: game.game_id,
            player: game.player,
            status: GameStatus::Completed,
            current_level: game.current_level,
            created_at: game.created_at,
            score: final_score,
        };
        store.set_game(updated_game);
    }

    // Private utility methods for item generation and game calculations
    fn spawn_items_of_type(
        ref store: Store,
        game_id: u32,
        level: u32,
        ref item_counter: u32,
        item_type: ItemType,
        count: u32,
    ) {
        let mut i = 0_u32;
        loop {
            if i >= count {
                break;
            }

            let item_id = Self::generate_item_id(game_id, level, item_counter);
            let (x, y) = Self::generate_item_position(game_id, level, item_counter);

            let world_item = WorldItem {
                game_id,
                item_id,
                item_type,
                x_position: x,
                y_position: y,
                is_collected: false,
                level,
            };

            store.set_world_item(world_item);

            item_counter += 1;
            i += 1;
        };
    }

    fn calculate_level_health_potions(level: u32) -> u32 {
        // Linear scaling: 3 base + 1 per level, capped at 10
        let potions = 3 + level;
        if potions > 10 {
            10
        } else {
            potions
        }
    }

    fn calculate_level_survival_kits(level: u32) -> u32 {
        // Moderate scaling: 1 kit per 2 levels, capped at 3
        let kits = (level + 1) / 2;
        if kits > 3 {
            3
        } else {
            kits
        }
    }

    fn calculate_level_books(level: u32) -> u32 {
        // Rare spawning: 1 book per 3 levels, capped at 2
        let books = level / 3;
        if books > 2 {
            2
        } else {
            books
        }
    }

    fn generate_item_id(game_id: u32, level: u32, item_counter: u32) -> u32 {
        let hash = poseidon_hash_span(
            array![game_id.into(), level.into(), item_counter.into()].span(),
        );
        // Constrain hash to u32 range to prevent overflow errors
        let hash_u256: u256 = hash.into();
        // Constrain to u32 maximum to prevent overflow
        let item_id = (hash_u256 % 0x100000000_u256).try_into().unwrap();
        item_id
    }

    fn generate_item_position(game_id: u32, level: u32, item_counter: u32) -> (u32, u32) {
        let seed_x = poseidon_hash_span(
            array![game_id.into(), level.into(), item_counter.into(), 'POSX'.into()].span(),
        );
        let seed_y = poseidon_hash_span(
            array![game_id.into(), level.into(), item_counter.into(), 'POSY'.into()].span(),
        );

        let x_u256: u256 = seed_x.into();
        let y_u256: u256 = seed_y.into();

        // X coordinate: 10-109 range
        let x = ((x_u256 % 100) + 10).try_into().unwrap();
        // Y coordinate: 10-109 range
        let y = ((y_u256 % 100) + 10).try_into().unwrap();
        (x, y)
    }
}
