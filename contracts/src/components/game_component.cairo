use starknet::ContractAddress;
use core::poseidon::poseidon_hash_span;
use super::super::helpers::store::{Store, StoreTrait};
use super::super::models::game::{Game, LevelItems};
use super::super::models::player::Player;
use super::super::models::world_state::WorldItem;
use super::super::types::game_types::GameStatus;
use super::super::types::item_types::ItemType;

// Game Component - handles game lifecycle and level management
#[generate_trait]
pub impl GameComponentImpl of GameComponentTrait {
    
    fn start_level(
        ref store: Store,
        player: ContractAddress,
        game_id: u32,
        level: u32
    ) -> u32 {
        // Verify game exists and player owns it
        let mut game = store.get_game(game_id);
        assert(game.player == player, 'Not your game');
        assert(game.status == GameStatus::InProgress, 'Game not in progress');
        
        // Update game level
        let updated_game = Game {
            game_id: game.game_id,
            player: game.player,
            status: game.status,
            current_level: level,
            created_at: game.created_at,
            score: game.score,
        };
        store.update_game(updated_game);
        
        // Calculate items for this level
        let health_potions_count = Self::calculate_level_health_potions(level);
        let survival_kits_count = Self::calculate_level_survival_kits(level);
        let books_count = Self::calculate_level_books(level);
        
        // Create level items metadata
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
        store.create_level_items(level_items);
        
        // Generate actual item instances
        let mut item_counter = 0_u32;
        
        // Generate health potions
        Self::spawn_items_of_type(
            ref store, 
            game_id, 
            level, 
            ref item_counter, 
            ItemType::HealthPotion, 
            health_potions_count
        );
        
        // Generate survival kits
        Self::spawn_items_of_type(
            ref store, 
            game_id, 
            level, 
            ref item_counter, 
            ItemType::SurvivalKit, 
            survival_kits_count
        );
        
        // Generate books
        Self::spawn_items_of_type(
            ref store, 
            game_id, 
            level, 
            ref item_counter, 
            ItemType::Book, 
            books_count
        );
        
        let total_items = health_potions_count + survival_kits_count + books_count;
        store.emit_level_started(player, game_id, level, total_items);
        
        total_items
    }
    
    fn complete_level(
        ref store: Store,
        player: ContractAddress,
        game_id: u32,
        level: u32
    ) -> bool {
        let game = store.get_game(game_id);
        assert(game.player == player, 'Not your game');
        assert(game.current_level == level, 'Not current level');
        
        let level_items = store.get_level_items(game_id, level);
        
        // Check if level is completed (all items collected)
        let items_completed = level_items.collected_health_potions == level_items.total_health_potions
            && level_items.collected_survival_kits == level_items.total_survival_kits
            && level_items.collected_books == level_items.total_books;
        
        if items_completed {
            // Award completion bonus
            let player_stats = store.get_player(player);
            let updated_player = Player {
                player: player_stats.player,
                health: player_stats.health,
                max_health: player_stats.max_health,
                level: player_stats.level,
                experience: player_stats.experience + 100, // Level completion bonus
                items_collected: player_stats.items_collected,
            };
            store.update_player(updated_player);
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
        store.update_game(updated_game);
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
        store.update_game(updated_game);
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
        store.update_game(updated_game);
    }
    
    // Helper methods
    fn spawn_items_of_type(
        ref store: Store,
        game_id: u32,
        level: u32,
        ref item_counter: u32,
        item_type: ItemType,
        count: u32
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
            
            store.spawn_world_item(world_item);
            
            item_counter += 1;
            i += 1;
        };
    }
    
    fn calculate_level_health_potions(level: u32) -> u32 {
        // Formula: base 3 potions + 1 per level, max 10
        let potions = 3 + level;
        if potions > 10 { 10 } else { potions }
    }
    
    fn calculate_level_survival_kits(level: u32) -> u32 {
        // Formula: 1 survival kit every 2 levels, max 3
        let kits = (level + 1) / 2;
        if kits > 3 { 3 } else { kits }
    }
    
    fn calculate_level_books(level: u32) -> u32 {
        // Formula: 1 book every 3 levels, max 2
        let books = level / 3;
        if books > 2 { 2 } else { books }
    }
    
    fn generate_item_id(game_id: u32, level: u32, item_counter: u32) -> u32 {
        let hash = poseidon_hash_span(
            array![game_id.into(), level.into(), item_counter.into()].span(),
        );
        // Use modulo to ensure the value fits in u32 range
        let hash_u256: u256 = hash.into();
        let item_id = (hash_u256 % 0x100000000_u256).try_into().unwrap(); // Max u32 value
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
        
        let x = ((x_u256 % 100) + 10).try_into().unwrap(); // X position between 10-109
        let y = ((y_u256 % 100) + 10).try_into().unwrap(); // Y position between 10-109
        (x, y)
    }
}