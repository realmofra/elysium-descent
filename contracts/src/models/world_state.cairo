use starknet::{ContractAddress, contract_address_const};
use elysium_descent::types::item_types::ItemType;

// Simplified world item for current implementation
#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct WorldItem {
    #[key]
    pub game_id: u32,
    #[key]
    pub item_id: u32,
    pub item_type: ItemType,
    pub x_position: u32,
    pub y_position: u32,
    pub is_collected: bool,
    pub level: u32,
}

// Helper functions for WorldItem - explicitly uses ContractAddress
#[generate_trait]
impl WorldItemImpl of WorldItemTrait {
    fn is_owned_by(self: @WorldItem, player: ContractAddress) -> bool {
        // This could be extended to track item ownership
        // For now, just demonstrating explicit ContractAddress usage
        player != contract_address_const::<0>()
    }

    fn can_be_collected_by(self: @WorldItem, player: ContractAddress) -> bool {
        !*self.is_collected && player != contract_address_const::<0>()
    }
}
