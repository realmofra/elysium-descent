use starknet::{ContractAddress, contract_address_const};
use elysium_descent::types::item::ItemType;

/// World item model representing collectible items placed in the game world
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

/// WorldItem utility functions for ownership and collection validation
#[generate_trait]
impl WorldItemImpl of WorldItemTrait {
    fn is_owned_by(self: @WorldItem, player: ContractAddress) -> bool {
        // Basic validation - could be extended for ownership tracking in future
        player != contract_address_const::<0>()
    }

    fn can_be_collected_by(self: @WorldItem, player: ContractAddress) -> bool {
        !*self.is_collected && player != contract_address_const::<0>()
    }
}
