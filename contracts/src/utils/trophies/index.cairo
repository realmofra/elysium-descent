use achievement::types::task::Task as BushidoTask;
use elysium_descent::utils::trophies;

pub const TROPHY_COUNT: u8 = 9;

#[derive(Copy, Drop)]
enum Trophy {
    None,
    CollectorI,
    CollectorII,
    CollectorIII,
    LootI,
    LootII,
    LootIII,
    WreckedGuardI,
    WreckedGuardII,
    WreckedGuardIII,
}

#[generate_trait]
impl TrophyImpl of TrophyTrait {
    #[inline]
    fn identifier(self: Trophy) -> felt252 {
        match self {
            Trophy::None => 0,
            Trophy::CollectorI => trophies::collector::Collector::identifier(0),
            Trophy::CollectorII => trophies::collector::Collector::identifier(1),
            Trophy::CollectorIII => trophies::collector::Collector::identifier(2),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::identifier(0),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::identifier(1),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::identifier(2),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::identifier(0),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::identifier(1),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::identifier(2),
        }
    }

    #[inline]
    fn hidden(self: Trophy) -> bool {
        match self {
            Trophy::None => true,
            Trophy::CollectorI => trophies::collector::Collector::hidden(0),
            Trophy::CollectorII => trophies::collector::Collector::hidden(0),
            Trophy::CollectorIII => trophies::collector::Collector::hidden(1),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::hidden(2),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::hidden(0),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::hidden(1),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::hidden(2),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::hidden(0),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::hidden(1),
        }
    }

    #[inline]
    fn index(self: Trophy) -> u8 {
        match self {
            Trophy::None => 0,
            Trophy::CollectorI => trophies::collector::Collector::index(0),
            Trophy::CollectorII => trophies::collector::Collector::index(0),
            Trophy::CollectorIII => trophies::collector::Collector::index(1),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::index(2),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::index(0),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::index(1),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::index(2),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::index(0),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::index(1),
        }
    }

    #[inline]
    fn points(self: Trophy) -> u16 {
        match self {
            Trophy::None => 0,
            Trophy::CollectorI => trophies::collector::Collector::points(0),
            Trophy::CollectorII => trophies::collector::Collector::points(1),
            Trophy::CollectorIII => trophies::collector::Collector::points(2),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::points(0),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::points(1),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::points(2),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::points(0),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::points(1),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::points(2),
        }
    }

    #[inline]
    fn group(self: Trophy) -> felt252 {
        match self {
            Trophy::None => 0,
            Trophy::CollectorI => trophies::collector::Collector::group(),
            Trophy::CollectorII => trophies::collector::Collector::group(),
            Trophy::CollectorIII => trophies::collector::Collector::group(),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::group(),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::group(),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::group(),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::group(),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::group(),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::group(),
        }
    }

    #[inline]
    fn icon(self: Trophy) -> felt252 {
        match self {
            Trophy::None => 0,
            Trophy::CollectorI => trophies::collector::Collector::icon(0),
            Trophy::CollectorII => trophies::collector::Collector::icon(1),
            Trophy::CollectorIII => trophies::collector::Collector::icon(2),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::icon(0),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::icon(1),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::icon(2),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::icon(0),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::icon(1),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::icon(2),
        }
    }

    #[inline]
    fn title(self: Trophy) -> felt252 {
        match self {
            Trophy::None => 0,
            Trophy::CollectorI => trophies::collector::Collector::title(0),
            Trophy::CollectorII => trophies::collector::Collector::title(1),
            Trophy::CollectorIII => trophies::collector::Collector::title(2),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::title(0),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::title(1),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::title(2),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::title(0),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::title(1),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::title(2),
        }
    }

    #[inline]
    fn description(self: Trophy) -> ByteArray {
        match self {
            Trophy::None => "",
            Trophy::CollectorI => trophies::collector::Collector::description(0),
            Trophy::CollectorII => trophies::collector::Collector::description(1),
            Trophy::CollectorIII => trophies::collector::Collector::description(2),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::description(0),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::description(1),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::description(2),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::description(0),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::description(1),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::description(
                2,
            ),
        }
    }

    #[inline]
    fn tasks(self: Trophy) -> Span<BushidoTask> {
        match self {
            Trophy::None => [].span(),
            Trophy::CollectorI => trophies::collector::Collector::tasks(0),
            Trophy::CollectorII => trophies::collector::Collector::tasks(1),
            Trophy::CollectorIII => trophies::collector::Collector::tasks(2),
            Trophy::LootI => trophies::sunken_chest::LootSunkenChest::tasks(0),
            Trophy::LootII => trophies::sunken_chest::LootSunkenChest::tasks(1),
            Trophy::LootIII => trophies::sunken_chest::LootSunkenChest::tasks(2),
            Trophy::WreckedGuardI => trophies::wreck_guardian::DefeatWreckGuardian::tasks(0),
            Trophy::WreckedGuardII => trophies::wreck_guardian::DefeatWreckGuardian::tasks(1),
            Trophy::WreckedGuardIII => trophies::wreck_guardian::DefeatWreckGuardian::tasks(2),
        }
    }

    #[inline]
    fn data(self: Trophy) -> ByteArray {
        ""
    }
}

impl IntoTrophyU8 of core::traits::Into<Trophy, u8> {
    #[inline]
    fn into(self: Trophy) -> u8 {
        match self {
            Trophy::None => 0,
            Trophy::CollectorI => 1,
            Trophy::CollectorII => 2,
            Trophy::CollectorIII => 3,
            Trophy::LootI => 4,
            Trophy::LootII => 5,
            Trophy::LootIII => 6,
            Trophy::WreckedGuardI => 7,
            Trophy::WreckedGuardII => 8,
            Trophy::WreckedGuardIII => 9,
        }
    }
}

impl IntoU8Trophy of core::traits::Into<u8, Trophy> {
    #[inline]
    fn into(self: u8) -> Trophy {
        let card: felt252 = self.into();
        match card {
            0 => Trophy::None,
            1 => Trophy::CollectorI,
            2 => Trophy::CollectorII,
            3 => Trophy::CollectorIII,
            4 => Trophy::LootI,
            5 => Trophy::LootII,
            6 => Trophy::LootIII,
            7 => Trophy::WreckedGuardI,
            8 => Trophy::WreckedGuardII,
            9 => Trophy::WreckedGuardIII,
            _ => Trophy::None,
        }
    }
}
