#[starknet::interface]
trait IGame<T> {
    fn start_game(ref self: T);
    fn level(self: @T, game_id: u128) -> u8;
    fn total_games(self: @T) -> u128;
}

#[dojo::contract]
mod game {
    use death_mountain::models::adventurer::adventurer::IAdventurer;
    use elysium_descent::components::countable::CountableComponent;
    use elysium_descent::constants::world::{DEFAULT_NS};
    use elysium_descent::utils::store::{Store, StoreTrait};
    use elysium_descent::models::game_counter::{GameCounter, GameCounterTrait};
    use elysium_descent::models::game::{Game, ImplGame};
    use dojo::event::EventStorage;
    use dojo::model::{Model, ModelStorage, ModelValueStorage};
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use death_mountain::models::adventurer::adventurer::{Adventurer, ImplAdventurer};

    component!(path: CountableComponent, storage: countable, event: CountableEvent);
    impl CountableImpl = CountableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        countable: CountableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        CountableEvent: CountableComponent::Event,
    }

    fn dojo_init(self: @ContractState) {
        self.countable.initialize(self.world_storage());
    }

    #[abi(embed_v0)]
    impl GameImpl of super::IGame<ContractState> {
        fn start_game(ref self: ContractState) {
            let world = self.world_storage();
            let mut store: Store = StoreTrait::new(world);
            let mut game_id: GameCounter = store.get_game_counter(1);

            //TODO: Make starting item dynamic
            let game: Game = ImplGame::new(game_id.count, 0);

            store.set_game(game);
            game_id.increment();
            store.set_game_counter(game_id);
        }

        //TODO: Change level system
        fn level(self: @ContractState, game_id: u128) -> u8 {
            let world = self.world_storage();
            let mut store: Store = StoreTrait::new(world);
            let game = store.get_game(game_id);
            let mut adventurer: Adventurer = ImplAdventurer::unpack(game.packed_adventurer);
            ImplAdventurer::get_level(adventurer)
        }

        fn total_games(self: @ContractState) -> u128 {
            let world = self.world_storage();
            let mut store: Store = StoreTrait::new(world);
            let count = store.get_game_counter(1);
            count.count - 1
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn world_storage(self: @ContractState) -> WorldStorage {
            self.world(@DEFAULT_NS())
        }
    }
}
