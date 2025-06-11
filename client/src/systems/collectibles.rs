use avian3d::prelude::*;
use bevy::prelude::*;

use crate::systems::character_controller::CharacterController;

// ===== COMPONENTS & RESOURCES =====

#[derive(Resource)]
pub struct FruitCollector {
    pub fruits_collected: u32,
}

#[derive(Component)]
pub struct Fruit;

#[derive(Component)]
pub struct FloatingItem {
    pub base_height: f32,
    pub hover_amplitude: f32,
    pub hover_speed: f32,
}

#[derive(Component, Clone, Copy, Debug)]
pub enum FruitType {
    Apple,
    Tomato,
}

#[derive(Component)]
pub struct Sensor;

// ===== PLUGIN =====

pub struct CollectiblesPlugin;

impl Plugin for CollectiblesPlugin {
    fn build(&self, app: &mut App) {
        app.insert_resource(FruitCollector { fruits_collected: 0 })
            .add_systems(Update, (
                collect_fruits,
                update_floating_items,
            ));
    }
}

// ===== SYSTEMS =====

pub fn spawn_fruit(
    commands: &mut Commands,
    assets: &Res<AssetServer>,
    fruit_type: FruitType,
    position: Vec3,
    scale: f32,
) {
    let model_path = match fruit_type {
        FruitType::Apple => "models/food/apple.glb#Scene0",
        FruitType::Tomato => "models/food/tomato.glb#Scene0",
    };
    
    let model_handle = assets.load(model_path);
    
    commands.spawn((
        Name::new(format!("{:?}", fruit_type)),
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
        Fruit,
        fruit_type,
        FloatingItem {
            base_height: position.y,
            hover_amplitude: 0.2,
            hover_speed: 2.0,
        },
        Sensor,
    ));
}

fn collect_fruits(
    mut commands: Commands,
    mut fruit_collector: ResMut<FruitCollector>,
    player_query: Query<&Transform, With<CharacterController>>,
    fruit_query: Query<(Entity, &Transform, &FruitType), With<Fruit>>,
) {
    let Ok(player_transform) = player_query.single() else {
        return;
    };

    for (fruit_entity, fruit_transform, fruit_type) in fruit_query.iter() {
        let distance = player_transform.translation.distance(fruit_transform.translation);
        if distance < 5.0 { // Collection radius
            info!("Collected a {:?}!", fruit_type);
            commands.entity(fruit_entity).despawn();
            fruit_collector.fruits_collected += 1;
            info!("Total fruits collected: {}", fruit_collector.fruits_collected);
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