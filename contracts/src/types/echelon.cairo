#[derive(Copy, Drop, PartialEq)]
pub enum Echelon {
    Pawn,
    Boss,
    King,
}

pub impl IntoEchelonU8 of core::traits::Into<Echelon, u8> {
    #[inline]
    fn into(self: Echelon) -> u8 {
        match self {
            Echelon::None => 0,
            Echelon::Pawn => 1,
            Echelon::Boss => 2,
            Echelon::King => 3,
        }
    }
}

pub impl IntoU8Echelon of core::traits::Into<u8, Echelon> {
    #[inline]
    fn into(self: u8) -> Echelon {
        match self {
            0 => Echelon::None,
            1 => Echelon::Pawn,
            2 => Echelon::Boss,
            3 => Echelon::King,
            _ => Echelon::None,
        }
}
