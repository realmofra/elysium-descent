use starknet::ContractAddress;

// Simplified player stats model for current implementation
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub health: u32,
    pub max_health: u32,
    pub level: u32,
    pub experience: u32,
    pub items_collected: u32,
}





