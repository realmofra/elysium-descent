#[starknet::interface]
trait IGame<T> {
    fn start_game(ref self: T, game_id: u64);
    fn health(self: @T, game_id: u64) -> u8;
    fn level(self: @T, game_id: u64) -> u8;
    fn xp(self: @T, game_id: u64) -> u16;
}

#[dojo::contract]
mod game {
    use death_mountain::models::adventurer::stats::{ImplStats, Stats};
    use death_mountain::components::countable::CountableComponent;
    use dojo::event::EventStorage;
    use dojo::model::{Model, ModelStorage, ModelValueStorage};
    use dojo::world::{WorldStorage, WorldStorageTrait};

    #[abi(embed_v0)]
    impl GameImpl of IGame<ContractState> {
        fn start_game(ref self: ContractState, game_id: u64) {}

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
    }
}
