pub mod systems {
    pub mod actions;
}

pub mod models {
    pub mod index;
}

pub mod constants {
    pub mod world;
}

pub mod utils {
    pub mod trophies;
    pub mod tasks;
    pub mod achievements;
}

#[cfg(test)]
mod tests {
    mod test_world;
}
