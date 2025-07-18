// External imports
use achievement::types::task::{Task as BushidoTask, TaskTrait as BushidoTaskTrait};

// Internal imports
use elysium_descent::utils::tasks;

// Types
#[derive(Copy, Drop)]
pub enum Task {
    None,
    Collector,
    DefeatWreckGuardian,
    LootSunkenChest,
    SpeakWithFisherman,
}

// Implementations
#[generate_trait]
pub impl TaskImpl of TaskTrait {
    #[inline]
    fn identifier(self: Task) -> felt252 {
        match self {
            Task::None => 0,
            Task::Collector => tasks::collector::Collector::identifier(),
            Task::DefeatWreckGuardian => tasks::wreck_guardian::DefeatWreckGuardian::identifier(),
            Task::LootSunkenChest => tasks::sunken_chest::LootSunkenChest::identifier(),
            Task::SpeakWithFisherman => tasks::fisherman::SpeakWithFisherman::identifier(),
        }
    }

    #[inline]
    fn description(self: Task, count: u32) -> ByteArray {
        match self {
            Task::None => "",
            Task::Collector => tasks::collector::Collector::description(count),
            Task::DefeatWreckGuardian => tasks::wreck_guardian::DefeatWreckGuardian::description(
                count,
            ),
            Task::LootSunkenChest => tasks::sunken_chest::LootSunkenChest::description(count),
            Task::SpeakWithFisherman => tasks::fisherman::SpeakWithFisherman::description(count),
        }
    }

    #[inline]
    fn tasks(self: Task, count: u32) -> Span<BushidoTask> {
        let task_id: felt252 = self.identifier();
        let description: ByteArray = self.description(count);
        array![BushidoTaskTrait::new(task_id, count.into(), description)].span()
    }
}

impl IntoTaskU8 of core::traits::Into<Task, u8> {
    #[inline]
    fn into(self: Task) -> u8 {
        match self {
            Task::None => 0,
            Task::Collector => 1,
            Task::DefeatWreckGuardian => 2,
            Task::LootSunkenChest => 3,
            Task::SpeakWithFisherman => 4,
        }
    }
}

impl IntoU8Task of core::traits::Into<u8, Task> {
    #[inline]
    fn into(self: u8) -> Task {
        let card: felt252 = self.into();
        match card {
            0 => Task::None,
            1 => Task::Collector,
            2 => Task::DefeatWreckGuardian,
            3 => Task::LootSunkenChest,
            4 => Task::SpeakWithFisherman,
            _ => Task::None,
        }
    }
}
