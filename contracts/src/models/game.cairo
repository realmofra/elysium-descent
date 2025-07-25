use starknet::{get_caller_address};
use death_mountain::models::adventurer::adventurer::{ImplAdventurer};
pub use elysium_descent::models::index::Game;

#[generate_trait]
pub impl ImplGame of GameTrait {
    #[inline]
    fn new(game_id: u128, starting_item: u8) -> Game {
        let mut adventurer = ImplAdventurer::new(starting_item);
        let packed_adventurer = ImplAdventurer::pack(adventurer);
        Game {
            game_id: game_id, player: get_caller_address(), packed_adventurer: packed_adventurer,
        }
    }
}
