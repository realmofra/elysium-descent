pub mod systems {
    pub mod game {
        pub mod contracts;
    }
}

pub mod models {
    pub mod index;
    pub mod game;
    pub mod game_counter;
}

pub mod components {
    pub mod countable;
}

pub mod constants {
    pub mod world;
}

pub mod utils {
    pub mod trophies;
    pub mod tasks;
    pub mod achievements;
    pub mod store;
}

#[cfg(test)]
mod tests {
    mod test_world;
}
