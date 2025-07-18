use elysium_descent::utils::tasks::interface::TaskTrait;

pub impl LootSunkenChest of TaskTrait {
    #[inline]
    fn identifier() -> felt252 {
        'LOOT_CHEST'
    }

    #[inline]
    fn description(count: u32) -> ByteArray {
        format!("Open {} sunken chest", count),
    }
}
