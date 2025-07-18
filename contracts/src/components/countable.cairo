#[starknet::component]
pub mod CountableComponent {
    // Dojo imports
    use dojo::world::WorldStorage;

    // Internal imports
    use elysium_descent::utils::store::{Store, StoreTrait};
    use elysium_descent::models::game_counter::{GameCounter, GameCounterTrait};

    // Storage
    #[storage]
    pub struct Storage {}

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}

    #[generate_trait]
    pub impl InternalImpl<TState, +HasComponent<TState>> of InternalTrait<TState> {
        /// Initializes the game counter
        ///
        /// # Arguments
        /// * `self` - Reference to the component state
        /// * `world` - The World dispatcher
        ///
        /// # Effects
        /// * Sets up the initial game counter in the world state
        fn initialize(self: @ComponentState<TState>, world: WorldStorage) {
            // [Effect] Initialize component
            let mut store: Store = StoreTrait::new(world);
            let current_game_counter: GameCounter = store.get_game_counter(1);

            assert(current_game_counter.count == 0, 'Counter already initialized');

            // [Effect] Create GameCounter
            let mut game_counter: GameCounter = GameCounterTrait::new();

            // [Effect] GameCounter increment
            game_counter.increment();

            store.set_game_counter(game_counter);
        }
    }
}
