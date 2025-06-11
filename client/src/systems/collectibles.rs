use avian3d::prelude::*;
use bevy::prelude::*;

use crate::systems::character_controller::CharacterController;

// ===== COMPONENTS & RESOURCES =====

#[derive(Resource)]
pub struct CollectibleCounter {
    pub collectibles_collected: u32,
}

#[derive(Component)]
pub struct Collectible;

#[derive(Component)]
pub struct FloatingItem {
    pub base_height: f32,
    pub hover_amplitude: f32,
    pub hover_speed: f32,
}

#[derive(Component, Clone, Copy, Debug)]
pub enum CollectibleType {
    Apple,
    Tomato,
    Pumpkin,
    Radish,
    Mushroom,
}

#[derive(Component)]
pub struct Sensor;

// ===== PLUGIN =====

pub struct CollectiblesPlugin;

impl Plugin for CollectiblesPlugin {
    fn build(&self, app: &mut App) {
        app.insert_resource(CollectibleCounter { collectibles_collected: 0 })
            .add_systems(Update, (
                collect_items,
                update_floating_items,
            ));
    }
}

// ===== SYSTEMS =====

pub fn spawn_collectible(
    commands: &mut Commands,
    assets: &Res<AssetServer>,
    collectible_type: CollectibleType,
    position: Vec3,
    scale: f32,
) {
    let model_path = match collectible_type {
        CollectibleType::Apple => "models/food/apple.glb#Scene0",
        CollectibleType::Tomato => "models/food/tomato.glb#Scene0",
        CollectibleType::Pumpkin => "models/food/pumpkin.glb#Scene0",
        CollectibleType::Radish => "models/food/radish.glb#Scene0",
        CollectibleType::Mushroom => "models/food/mushroom.glb#Scene0",
    };
    
    let model_handle = assets.load(model_path);
    
    commands.spawn((
        Name::new(format!("{:?}", collectible_type)),
        SceneRoot(model_handle),
        Transform {
            translation: position,
            scale: Vec3::splat(scale),
            ..default()
        },
        ColliderConstructorHierarchy::new(ColliderConstructor::TrimeshFromMesh),
        RigidBody::Kinematic,
        Friction::new(0.5),
        Restitution::new(0.0),
        Visibility::Visible,
        InheritedVisibility::default(),
        ViewVisibility::default(),
        Collectible,
        collectible_type,
        FloatingItem {
            base_height: position.y,
            hover_amplitude: 0.2,
            hover_speed: 2.0,
        },
        Sensor,
    ));
}

fn collect_items(
    mut commands: Commands,
    mut collectible_counter: ResMut<CollectibleCounter>,
    player_query: Query<&Transform, With<CharacterController>>,
    collectible_query: Query<(Entity, &Transform, &CollectibleType), With<Collectible>>,
) {
    let Ok(player_transform) = player_query.single() else {
        return;
    };

    for (collectible_entity, collectible_transform, collectible_type) in collectible_query.iter() {
        let distance = player_transform.translation.distance(collectible_transform.translation);
        if distance < 5.0 { // Collection radius
            info!("Collected a {:?}!", collectible_type);
            commands.entity(collectible_entity).despawn();
            collectible_counter.collectibles_collected += 1;
            info!("Total collectibles collected: {}", collectible_counter.collectibles_collected);
        }
    }
}

fn update_floating_items(time: Res<Time>, mut query: Query<(&FloatingItem, &mut Transform)>) {
    for (floating, mut transform) in query.iter_mut() {
        let time = time.elapsed_secs();
        let hover_offset = (time * floating.hover_speed).sin() * floating.hover_amplitude;
        transform.translation.y = floating.base_height + hover_offset;
    }
} 