#[starknet::interface]
trait IGame<T> {
    fn start_game(ref self: T);
    fn health(self: @T, game_id: u64) -> u8;
    fn level(self: @T, game_id: u64) -> u8;
    fn xp(self: @T, game_id: u64) -> u16;
    fn game_count(self: @T) -> u128;
}

#[dojo::contract]
mod game {
    use elysium_descent::components::countable::CountableComponent;
    use elysium_descent::constants::world::{DEFAULT_NS};
    use elysium_descent::utils::store::{Store, StoreTrait};
    use elysium_descent::models::game_counter::{GameCounter, GameCounterTrait};
    use dojo::event::EventStorage;
    use dojo::model::{Model, ModelStorage, ModelValueStorage};
    use dojo::world::{WorldStorage, WorldStorageTrait};

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
            let mut game_id = store.get_game_counter(1);

            // Initialize game ID
            game_id.increment();
            store.set_game_counter(game_id);
        }

        fn health(self: @ContractState, game_id: u64) -> u8 {
            // Implementation for getting health
            100
        }

        fn level(self: @ContractState, game_id: u64) -> u8 {
            // Implementation for getting level
            1
        }

        fn xp(self: @ContractState, game_id: u64) -> u16 {
            // Implementation for getting XP
            0
        }

        fn game_count(self: @ContractState) -> u128 {
            let world = self.world_storage();
            let mut store: Store = StoreTrait::new(world);
            let count = store.get_game_counter(1);
            count.count
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn world_storage(self: @ContractState) -> WorldStorage {
            self.world(@DEFAULT_NS())
        }
    }
}
