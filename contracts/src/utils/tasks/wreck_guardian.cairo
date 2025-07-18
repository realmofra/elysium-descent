use elysium_descent::utils::tasks::interface::TaskTrait;

pub impl DefeatWreckGuardian of TaskTrait {
    #[inline]
    fn identifier() -> felt252 {
        'WRECK_GUARDIAN'
    }

    #[inline]
    fn description(count: u32) -> ByteArray {
        format!("Defeat {} wreck guardian", count)
    }
}
