use starknet::ContractAddress;

// Global game counter for unique game IDs
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GameCounter {
    #[key]
    pub id: u32,
    pub count: u128,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Game {
    #[key]
    pub game_id: u128,
    pub player: ContractAddress,
    pub packed_adventurer: felt252,
}
