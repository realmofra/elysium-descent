use elysium_descent::utils::tasks::interface::TaskTrait;

pub impl Collector of TaskTrait {
    #[inline]
    fn identifier() -> felt252 {
        'COLLECTOR'
    }

    #[inline]
    fn description(count: u32) -> ByteArray {
        format!("Collect {} gold coins", count)
    }
}
