#[derive(Copy, Drop, PartialEq)]
pub enum Loot {
    None,
    Gold,
    Equipment,
    LORDS,
    Consumable,
}

pub impl IntoLootU8 of core::traits::Into<Loot, u8> {
    #[inline]
    fn into(self: Loot) -> u8 {
        match self {
            Loot::None => 0,
            Loot::Gold => 1,
            Loot::Equipment => 2,
            Loot::LORDS => 3,
            Loot::Consumable => 4,
        }
    }
}

pub impl IntoU8Loot of core::traits::Into<u8, Loot> {
    #[inline]
    fn into(self: u8) -> Loot {
        match self {
            0 => Loot::None,
            1 => Loot::Gold,
            2 => Loot::Equipment,
            3 => Loot::LORDS,
            4 => Loot::Consumable,
            _ => Loot::None,
        }
    }
}
