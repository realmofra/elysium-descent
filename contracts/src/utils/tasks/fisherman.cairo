use elysium_descent::utils::tasks::interface::TaskTrait;

pub impl SpeakWithFisherman of TaskTrait {
    #[inline]
    fn identifier() -> felt252 {
        'FISHERMAN'
    }

    #[inline]
    fn description(count: u32) -> ByteArray {
        "Speak with the fisherman",
    }
}
