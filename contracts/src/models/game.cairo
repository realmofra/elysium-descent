use starknet::{get_caller_address};
use death_mountain::models::adventurer::adventurer::{ImplAdventurer};
pub use elysium_descent::models::index::EGame;

#[generate_trait]
pub impl ImplGame of GameTrait {
    #[inline]
    fn new(game_id: u128) -> EGame {
        EGame { game_id: game_id, player: get_caller_address(), adventurer: ImplAdventurer::new(0) }
    }
}
