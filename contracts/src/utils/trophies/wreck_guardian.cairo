use achievement::types::task::{Task as BushidoTask};
use elysium_descent::utils::tasks::index::{Task, TaskImpl};
use elysium_descent::utils::trophies::interface::{TrophyTrait};

pub impl DefeatWreckGuardian of TrophyTrait {
    #[inline]
    fn identifier(level: u8) -> felt252 {
        match level {
            0 => 'WreckedGuard_I',
            1 => 'WreckedGuard_II',
            2 => 'WreckedGuard_III',
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
        'Wreacked Guard'
    }

    #[inline]
    fn icon(level: u8) -> felt252 {
        'fa-democrat'
    }

    #[inline]
    fn title(level: u8) -> felt252 {
        match level {
            0 => 'Wreacked Guard I',
            1 => 'Wreacked Guard II',
            2 => 'Wreacked Guard III',
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
            0 => 30,
            1 => 100,
            2 => 1000,
            _ => 0,
        };
        Task::DefeatWreckGuardian.tasks(count)
    }
}
