use starknet::ContractAddress;
use super::super::types::item_types::ItemType;

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





