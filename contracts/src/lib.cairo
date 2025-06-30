pub mod interfaces;

pub mod helpers {
    pub mod store;
}

pub mod components {
    pub mod inventory;
    pub mod game;
}

pub mod systems {
    pub mod actions;
    pub mod elysium_dungeon;
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

pub mod elements {
    pub mod base;
    pub mod factory;
    pub mod items {
        pub mod health_potion;
        pub mod survival_kit;
        pub mod book;
    }
}

#[cfg(test)]
mod tests {
    // Legacy test modules (keeping for compatibility)
    mod world;
    mod simple;
    mod comprehensive;

    // New feature-based test modules
    pub mod setup;
    mod test_game_features;
    mod test_inventory_features;
    mod test_component_layer;
    mod test_error_conditions;
    mod test_performance;
    mod test_helpers;
    mod test_events;
    mod test_elements;
}
