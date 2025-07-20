use crate::systems::collectibles::{CollectibleConfig, CollectibleRotation, CollectibleType};
use bevy::math::Vec3;
use once_cell::sync::Lazy;

pub static COLLECTIBLES: Lazy<Vec<CollectibleConfig>> = Lazy::new(|| {
    vec![
        CollectibleConfig {
            position: Vec3::new(10.0, 2.0, 60.0),
            collectible_type: CollectibleType::Coin,
            scale: 0.7,
            rotation: Some(CollectibleRotation {
                enabled: true,
                clockwise: true,
                speed: 2.0,
            }),
        },
        CollectibleConfig {
            position: Vec3::new(20.0, 2.0, 60.0),
            collectible_type: CollectibleType::MysteryBox,
            scale: 1.0,
            rotation: Some(CollectibleRotation {
                enabled: true,
                clockwise: false,
                speed: 1.5,
            }),
        },
    ]
});
