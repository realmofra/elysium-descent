// Centralized animation indices to avoid magic numbers sprinkled across systems.

pub mod common {
    // Many spawns kick off with this initial idle index
    pub const INITIAL_IDLE: usize = 2;
}

pub mod player {
    pub const IDLE: usize = 3;
    pub const RUN: usize = 4;
    pub const WALK: usize = 7;

    pub const ATTACK_1: usize = 5;
    pub const ATTACK_2: usize = 6;
}

pub mod enemy {
    pub const IDLE: usize = 1;
    pub const RUN: usize = 4;
    pub const WALK: usize = 7;

    pub const ATTACK: usize = 3;
}


