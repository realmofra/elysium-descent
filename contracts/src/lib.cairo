pub mod helpers {
    pub mod store;
}

pub mod components {
    pub mod inventory;
    pub mod game;
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
    pub mod item;
    pub mod action;
    pub mod game;
}

#[cfg(test)]
mod tests {
    // Legacy test modules (keeping for compatibility)
    mod world;
    mod simple;
    mod comprehensive;
    mod setup;

    // New feature-based test modules
    mod test_game_features;
    mod test_inventory_features;
    mod test_component_layer;
    mod test_error_conditions;
    mod test_performance;
    mod test_helpers;
    // mod test_events;
}
