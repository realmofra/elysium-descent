use starknet::ContractAddress;

// Simplified player inventory for current implementation
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerInventory {
    #[key]
    pub player: ContractAddress,
    pub health_potions: u32,
    pub survival_kits: u32,
    pub books: u32,
    pub capacity: u32,
}




