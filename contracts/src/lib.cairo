pub mod helpers {
    pub mod store;
}

pub mod components {
    pub mod inventory_component;
    pub mod game_component;
}

pub mod systems {
    pub mod actions;
}

pub mod models {
    pub mod player;
    pub mod inventory;
    pub mod game;
    pub mod world_state;
    pub mod index;
}

pub mod types {
    pub mod item_types;
    pub mod action_types;
    pub mod game_types;
}

#[cfg(test)]
mod tests {
    mod test_world;
    mod test_simple;
    mod test_comprehensive;
    mod setup;
}
