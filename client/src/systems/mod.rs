pub mod book_interaction;
pub mod character_controller;
pub mod collectibles;
pub mod collectibles_config;
#[cfg(not(target_arch = "wasm32"))]
pub mod dojo;
#[cfg(target_arch = "wasm32")]
pub mod dojo {
    use bevy::prelude::*;

    // Stub events so the rest of the code can compile on wasm without pulling in networking deps
    #[derive(Event, Debug)]
    pub struct CreateGameEvent;

    pub mod pickup_item {
        use bevy::prelude::*;
        use crate::systems::collectibles::CollectibleType;

        #[derive(Event, Debug)]
        pub struct PickupItemEvent {
            pub item_type: CollectibleType,
            pub item_entity: Entity,
        }

        #[derive(Event, Debug)]
        pub struct ItemPickedUpEvent {
            pub item_type: CollectibleType,
            pub transaction_hash: String,
        }

        #[derive(Event, Debug)]
        pub struct ItemPickupFailedEvent {
            pub item_type: CollectibleType,
            pub error: String,
        }
    }
}
pub mod enemy_ai;
pub mod objectives;
