#[derive(Copy, Drop, PartialEq)]
pub enum Boss {
    Bear,
    Troll,
    Fairy,
}

pub impl IntoBossU8 of core::traits::Into<Boss, u8> {
    #[inline]
    fn into(self: Boss) -> u8 {
        match self {
            Boss::None => 0,
            Boss::Bear => 1,
            Boss::Troll => 2,
            Boss::Fairy => 3,
        }
    }
}

pub impl IntoU8Boss of core::traits::Into<u8, Boss> {
    #[inline]
    fn into(self: u8) -> Boss {
        match self {
            0 => Boss::None,
            1 => Boss::Bear,
            2 => Boss::Troll,
            3 => Boss::Fairy,
            _ => Boss::None,
        }
}
