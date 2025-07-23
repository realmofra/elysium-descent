use crate::assets::ModelAssets;
use avian3d::prelude::*;
use bevy::prelude::*;

use crate::screens::Screen;
use crate::systems::character_controller::CharacterController;
use crate::systems::dojo::PickupItemEvent;
use rand::prelude::*;
use crate::screens::gameplay::PlayingScene;
#[derive(Clone, Copy)]
enum PackPattern { Line, Row, V }

// ===== COMPONENTS & RESOURCES =====

#[derive(Component)]
pub struct Collectible;

#[derive(Component)]
pub struct Collected;

#[derive(Component, Clone)]
pub struct CollectibleRotation {
    pub enabled: bool,
    pub clockwise: bool,
    pub speed: f32,
}

#[derive(Component)]
pub struct FloatingItem {
    pub base_height: f32,
    pub hover_amplitude: f32,
    pub hover_speed: f32,
}

#[derive(Component, Clone, Copy, Debug, PartialEq)]
pub enum CollectibleType {
    Coin,
    MysteryBox,
}

#[derive(Resource)]
pub struct NextItemToAdd(pub CollectibleType);

#[derive(Resource)]
pub struct CollectibleSpawner {
    pub coins_spawned: usize,
    pub boxes_spawned: usize,
    pub timer: Timer,
}

impl Default for CollectibleSpawner {
    fn default() -> Self {
        Self {
            coins_spawned: 0,
            boxes_spawned: 0,
            timer: Timer::from_seconds(2.0, TimerMode::Repeating),
        }
    }
}

#[derive(Component)]
pub struct Sensor;

/// Component marking objects that can be interacted with
#[derive(Component, Clone, Copy)]
pub struct Interactable {
    pub interaction_radius: f32,
}

/// Event triggered when player presses interaction key
#[derive(Event, Debug)]
pub struct InteractionEvent;

// Configuration for spawning collectibles
#[derive(Clone)]
pub struct CollectibleConfig {
    pub position: Vec3,
    pub collectible_type: CollectibleType,
    pub scale: f32,
    pub rotation: Option<CollectibleRotation>,
}

#[derive(Resource, Default)]
pub struct PlayerMovementTracker {
    pub last_position: Option<Vec3>,
    pub time_stationary: f32,
    pub paused: bool,
}

// ===== PLUGIN =====

pub struct CollectiblesPlugin;

impl Plugin for CollectiblesPlugin {
    fn build(&self, app: &mut App) {
        app.add_event::<InteractionEvent>()
            .insert_resource(crate::ui::inventory::InventoryVisibilityState::default())
            .init_resource::<CollectibleSpawner>()
            .init_resource::<PlayerMovementTracker>()
            .add_systems(
                Update,
                (
                    auto_collect_nearby_interactables,
                    handle_interactions,
                    update_floating_items,
                    rotate_collectibles,
                    crate::ui::inventory::add_item_to_inventory,
                    crate::ui::inventory::toggle_inventory_visibility,
                    crate::ui::inventory::adjust_inventory_for_dialogs,
                    collectible_spawner_system,
                    track_player_movement,
                )
                    .run_if(in_state(Screen::GamePlay)),
            );
    }
}

// ===== SYSTEMS =====

pub fn spawn_collectible(
    commands: &mut Commands,
    assets: &Res<ModelAssets>,
    config: CollectibleConfig,
    scene_marker: impl Component + Clone,
) {
    let model_handle = match config.collectible_type {
        CollectibleType::Coin => assets.coin.clone(),
        CollectibleType::MysteryBox => assets.mystery_box.clone(),
    };

    let mut entity = commands.spawn((
        Name::new(format!("{:?}", config.collectible_type)),
        SceneRoot(model_handle),
        Transform {
            translation: config.position,
            scale: Vec3::splat(config.scale),
            ..default()
        },
        Collider::sphere(0.5),
        RigidBody::Kinematic,
        Visibility::Visible,
        InheritedVisibility::default(),
        ViewVisibility::default(),
        Collectible,
        config.collectible_type,
        FloatingItem {
            base_height: config.position.y,
            hover_amplitude: 0.2,
            hover_speed: 2.0,
        },
        Sensor,
        scene_marker.clone(),
        Interactable {
            interaction_radius: 4.0,
        },
    ));

    if let Some(rotation) = config.rotation {
        entity.insert(rotation);
    }
}

/// System to automatically collect any collectible when the player is within the Interactable's radius
fn auto_collect_nearby_interactables(
    mut commands: Commands,
    player_query: Query<&Transform, With<CharacterController>>,
    interactable_query: Query<
        (Entity, &Transform, &Interactable, &CollectibleType),
        Without<Collected>,
    >,
    mut pickup_events: EventWriter<PickupItemEvent>,
) {
    let Ok(player_transform) = player_query.single() else {
        return;
    };

    for (entity, transform, interactable, collectible_type) in interactable_query.iter() {
        let distance = player_transform.translation.distance(transform.translation);
        if distance <= interactable.interaction_radius {
            if *collectible_type == CollectibleType::Coin {
                // Mark as collected
                commands.entity(entity).insert(Collected);
                // Insert NextItemToAdd so inventory system will add it
                commands.insert_resource(NextItemToAdd(*collectible_type));
                // Despawn the entity immediately
                commands.entity(entity).despawn();
                // Trigger blockchain event
                pickup_events.write(PickupItemEvent {
                    item_type: *collectible_type,
                    item_entity: entity,
                });
            }
        }
    }
}

/// System to handle pressing E near a MysteryBox
fn handle_interactions(
    mut commands: Commands,
    player_query: Query<&Transform, With<CharacterController>>,
    interactable_query: Query<
        (Entity, &Transform, &Interactable, &CollectibleType),
        Without<Collected>,
    >,
    mut pickup_events: EventWriter<PickupItemEvent>,
    mut interaction_events: EventReader<InteractionEvent>,
) {
    let Ok(player_transform) = player_query.single() else {
        return;
    };
    let mut interacted = false;
    for _ in interaction_events.read() {
        for (entity, transform, interactable, collectible_type) in interactable_query.iter() {
            let distance = player_transform.translation.distance(transform.translation);
            if distance <= interactable.interaction_radius
                && *collectible_type == CollectibleType::MysteryBox
            {
                // Mark as collected
                commands.entity(entity).insert(Collected);
                // Insert NextItemToAdd so inventory system will add it
                commands.insert_resource(NextItemToAdd(*collectible_type));
                // Despawn the entity immediately
                commands.entity(entity).despawn();
                // Trigger blockchain event
                pickup_events.write(PickupItemEvent {
                    item_type: *collectible_type,
                    item_entity: entity,
                });
                // Optionally, trigger a dialog or event here
                interacted = true;
                break;
            }
        }
        if interacted {
            break;
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

pub fn rotate_collectibles(
    mut collectible_query: Query<(&mut Transform, &CollectibleRotation)>,
    time: Res<Time>,
) {
    for (mut transform, rotation) in collectible_query.iter_mut() {
        if rotation.enabled {
            let rotation_amount = if rotation.clockwise {
                rotation.speed * time.delta_secs()
            } else {
                -rotation.speed * time.delta_secs()
            };
            transform.rotate_y(rotation_amount);
        }
    }
}

// System to track player movement and update PlayerMovementTracker
fn track_player_movement(
    time: Res<Time>,
    player_query: Query<&Transform, With<CharacterController>>,
    mut tracker: ResMut<PlayerMovementTracker>,
) {
    let Ok(player_transform) = player_query.single() else { return; };
    let pos = player_transform.translation;
    let moved = if let Some(last) = tracker.last_position {
        pos.distance(last) > 0.05 // movement threshold
    } else {
        true
    };
    if moved {
        tracker.time_stationary = 0.0;
        tracker.paused = false;
        tracker.last_position = Some(pos);
    } else {
        tracker.time_stationary += time.delta_secs();
        if tracker.time_stationary >= 4.0 {
            tracker.paused = true;
        }
    }
}

pub fn collectible_spawner_system(
    mut commands: Commands,
    mut spawner: ResMut<CollectibleSpawner>,
    time: Res<Time>,
    player_query: Query<&Transform, With<CharacterController>>,
    assets: Res<ModelAssets>,
    existing_collectibles: Query<&Transform, With<Collectible>>,
    tracker: ResMut<PlayerMovementTracker>,
) {
    if tracker.paused {
        return;
    }
    spawner.timer.tick(time.delta());
    if !spawner.timer.finished() {
        return;
    }
    let mut rng = rand::rng();
    let max_coins: usize = 100;
    let max_boxes: usize = 10;
    let to_spawn = 3;
    let mut spawn_types = Vec::new();
    let coins_left = max_coins.saturating_sub(spawner.coins_spawned);
    let boxes_left = max_boxes.saturating_sub(spawner.boxes_spawned);
    for _ in 0..to_spawn {
        if coins_left + boxes_left == 0 {
            break;
        }
        let roll = rng.random_range(0..(coins_left + boxes_left));
        if roll < coins_left {
            spawn_types.push(CollectibleType::Coin);
            spawner.coins_spawned += 1;
        } else {
            spawn_types.push(CollectibleType::MysteryBox);
            spawner.boxes_spawned += 1;
        }
    }
    if spawn_types.is_empty() {
        return;
    }
    let Ok(player_transform) = player_query.single() else { return; };
    let player_pos = player_transform.translation;
    let player_y = player_pos.y;
    // Elevation-based spawning rules
    if player_y >= -0.5 && player_y <= 7.5 {
        return; // Do not spawn
    }
    if player_y >= 9.5 && player_y <= 17.4 {
        return; // Do not spawn
    }
    let min_distance = 5.0; // at least 5m ahead
    let base_distance = 15.0; // meters ahead of player
    let patterns = [PackPattern::Line, PackPattern::Row, PackPattern::V];
    let pattern = *patterns.choose(&mut rng).unwrap();
    let spacing = 1.2;
    let base_forward = -player_transform.forward();
    let base_right = Vec3::new(base_forward.z, 0.0, -base_forward.x);
    let base_pos = player_pos + base_forward * base_distance;
    // Elevation rules for base_pos.y
    let mut base_y = player_y + 3.0;
    if player_y <= -1.5 {
        base_y = base_y.max(1.0);
    } else if (8.4..=8.6).contains(&player_y) {
        base_y = base_y.max(11.0);
    } else if (17.3..=17.5).contains(&player_y) {
        base_y = base_y.max(20.0);
    }
    // Generate positions for the pack
    let mut pack_positions = Vec::new();
    match pattern {
        PackPattern::Line => {
            for i in 0..3 {
                let offset = (i as f32 - 1.0) * spacing;
                let mut pos = base_pos + base_forward * offset;
                pos.y = base_y;
                pack_positions.push(pos);
            }
        }
        PackPattern::Row => {
            for i in 0..3 {
                let offset = (i as f32 - 1.0) * spacing;
                let mut pos = base_pos + base_right * offset;
                pos.y = base_y;
                pack_positions.push(pos);
            }
        }
        PackPattern::V => {
            let mut pos0 = base_pos;
            pos0.y = base_y;
            let mut pos1 = base_pos + (base_forward * -spacing + base_right * spacing).normalize() * spacing;
            pos1.y = base_y;
            let mut pos2 = base_pos + (base_forward * -spacing - base_right * spacing).normalize() * spacing;
            pos2.y = base_y;
            pack_positions.push(pos0);
            pack_positions.push(pos1);
            pack_positions.push(pos2);
        }
    }
    // Only spawn up to the number of available spawn_types
    for (pos, collectible_type) in pack_positions.into_iter().zip(spawn_types.into_iter()) {
        let too_close = existing_collectibles.iter().any(|t| t.translation.distance(pos) < min_distance);
        if too_close {
            continue;
        }
        let config = CollectibleConfig {
            position: pos,
            collectible_type,
            scale: if collectible_type == CollectibleType::Coin { 0.7 } else { 1.0 },
            rotation: Some(CollectibleRotation {
                enabled: true,
                clockwise: rng.random_bool(0.5),
                speed: rng.random_range(1.0..3.0),
            }),
        };
        spawn_collectible(&mut commands, &assets, config, PlayingScene);
    }
}
