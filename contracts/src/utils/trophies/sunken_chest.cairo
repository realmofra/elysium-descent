use achievement::types::task::{Task as BushidoTask};
use elysium_descent::utils::tasks::index::{Task, TaskImpl};
use elysium_descent::utils::trophies::interface::{TrophyTrait};

pub impl LootSunkenChest of TrophyTrait {
    #[inline]
    fn identifier(level: u8) -> felt252 {
        match level {
            0 => 'Loot_I',
            1 => 'Loot_II',
            2 => 'Loot_III',
            _ => '',
        }
    }

    #[inline]
    fn hidden(level: u8) -> bool {
        false
    }

    #[inline]
    fn index(level: u8) -> u8 {
        level
    }

    #[inline]
    fn points(level: u8) -> u16 {
        match level {
            0 => 20,
            1 => 40,
            2 => 80,
            _ => 0,
        }
    }

    #[inline]
    fn group() -> felt252 {
        'Loot'
    }

    #[inline]
    fn icon(level: u8) -> felt252 {
        'fa-democrat'
    }

    #[inline]
    fn title(level: u8) -> felt252 {
        match level {
            0 => 'Loot I',
            1 => 'Loot II',
            2 => 'Loot III',
            _ => '',
        }
    }

    #[inline]
    fn description(level: u8) -> ByteArray {
        "A stubborn mule is still better than no mule at all"
    }

    #[inline]
    fn tasks(level: u8) -> Span<BushidoTask> {
        let count: u32 = match level {
            0 => 2,
            1 => 10,
            2 => 100,
            _ => 0,
        };
        Task::LootSunkenChest.tasks(count)
    }
}
