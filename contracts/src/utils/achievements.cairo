use achievement::store::{Store, StoreTrait};
use elysium_descent::utils::tasks::index::{Task, TaskTrait};
use dojo::world::{WorldStorage};
use starknet::{get_block_timestamp, get_caller_address};

#[generate_trait]
impl AchievementsUtilsImpl of AchievementsUtilsTrait {
    fn loot(ref world: WorldStorage) {
        let store: Store = StoreTrait::new(world);
        let player_id: felt252 = get_caller_address().into();
        let time = get_block_timestamp();

        let task_id: felt252 = Task::LootSunkenChest.identifier();
        store.progress(player_id, task_id, count: 1, time: time);
    }

    fn collect(ref world: WorldStorage) {
        let store: Store = StoreTrait::new(world);
        let player_id: felt252 = get_caller_address().into();
        let time = get_block_timestamp();

        let task_id: felt252 = Task::Collector.identifier();
        store.progress(player_id, task_id, count: 1, time: time);
    }

    fn slay_monster(ref world: WorldStorage) {
        let store: Store = StoreTrait::new(world);
        let player_id: felt252 = get_caller_address().into();
        let time = get_block_timestamp();

        let task_id: felt252 = Task::DefeatWreckGuardian.identifier();
        store.progress(player_id, task_id, count: 1, time: time);
    }
}
