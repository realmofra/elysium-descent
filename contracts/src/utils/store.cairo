//! Store struct and component management methods.

// Dojo imports
use dojo::world::WorldStorage;
use dojo::model::ModelStorage;

// Models imports
use elysium_descent::models::game_counter::GameCounter;
use elysium_descent::models::game::Game;


// Structs
#[derive(Copy, Drop)]
pub struct Store {
    world: WorldStorage,
}

#[generate_trait]
pub impl StoreImpl of StoreTrait {
    #[inline]
    fn new(world: WorldStorage) -> Store {
        Store { world: world }
    }

    #[inline]
    fn set_game_counter(ref self: Store, count: GameCounter) {
        self.world.write_model(@count);
    }

    #[inline]
    fn get_game_counter(self: Store, id: u32) -> GameCounter {
        self.world.read_model(id)
    }

    #[inline]
    fn set_game(ref self: Store, game: Game) {
        self.world.write_model(@game);
    }

    #[inline]
    fn get_game(self: Store, id: u128) -> Game {
        self.world.read_model(id)
    }
}
