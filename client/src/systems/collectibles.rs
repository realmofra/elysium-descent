use crate::assets::ModelAssets;
use avian3d::prelude::*;
use bevy::prelude::*;
use rand::prelude::*;
use serde::{Deserialize, Serialize};
use std::fs;

use crate::screens::Screen;
use crate::systems::character_controller::CharacterController;
use crate::systems::dojo::PickupItemEvent;
use crate::screens::gameplay::PlayingScene;

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
}

#[derive(Resource)]
pub struct NextItemToAdd(pub CollectibleType);

#[derive(Resource)]
pub struct CollectibleSpawner {
    pub coins_spawned: usize,
}

impl Default for CollectibleSpawner {
    fn default() -> Self {
        Self {
            coins_spawned: 0,
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









// System to load navigation data from nav.json file
fn load_navigation_data_system(
    mut nav_spawner: ResMut<NavigationBasedSpawner>,
) {
    if nav_spawner.loaded {
        return;
    }

    match fs::read_to_string("nav.json") {
        Ok(contents) => {
            match serde_json::from_str::<NavigationData>(&contents) {
                Ok(nav_data) => {
                    nav_spawner.nav_positions = nav_data.positions
                        .iter()
                        .map(|point| Vec3::new(point.position[0], point.position[1], point.position[2]))
                        .collect();
                    
                    nav_spawner.loaded = true;
                    info!("✅ Loaded {} navigation positions from nav.json", nav_spawner.nav_positions.len());
                }
                Err(e) => {
                    error!("Failed to parse nav.json: {}", e);
                }
            }
        }
        Err(e) => {
            warn!("Could not load nav.json (file may not exist yet): {}", e);
        }
    }
}

// System to spawn collectibles around navigation positions
fn spawn_navigation_based_collectibles_system(
    mut commands: Commands,
    assets: Res<ModelAssets>,
    nav_spawner: Res<NavigationBasedSpawner>,
    mut collectible_spawner: ResMut<CollectibleSpawner>,
    spatial_query: SpatialQuery,
) {
    if !nav_spawner.loaded || collectible_spawner.coins_spawned > 0 {
        return;
    }

    let mut rng = rand::rng();
    let mut spawned_positions = Vec::new();
    let mut coins_spawned = 0;
    const MAX_COINS: usize = 50; // Limit total coins for sparse placement

    info!("🪙 Starting navigation-based coin spawning...");

    for nav_pos in &nav_spawner.nav_positions {
        // Random chance to spawn near this navigation position
        if rng.random::<f32>() > nav_spawner.spawn_probability {
            continue;
        }

        // Generate random position within spawn radius
        let angle = rng.random::<f32>() * std::f32::consts::TAU;
        let distance = rng.random::<f32>() * nav_spawner.spawn_radius;
        let offset = Vec3::new(
            angle.cos() * distance,
            0.0,
            angle.sin() * distance,
        );
        let potential_pos = *nav_pos + offset;

        // Check minimum distance from other coins
        let too_close = spawned_positions.iter().any(|&other_pos: &Vec3| {
            potential_pos.distance(other_pos) < nav_spawner.min_distance_between_coins
        });

        if too_close {
            continue;
        }

        // Validate position with collision detection - add 2.05 units elevation + 0.45 for coin height
        let coin_pos = Vec3::new(potential_pos.x, potential_pos.y + 2.5, potential_pos.z);
        if is_valid_coin_position(coin_pos, &spatial_query) {
            spawn_collectible(
                &mut commands,
                &assets,
                CollectibleConfig {
                    position: coin_pos,
                    collectible_type: CollectibleType::Coin,
                    scale: 0.75,
                    rotation: Some(CollectibleRotation {
                        enabled: true,
                        clockwise: true,
                        speed: 1.0,
                    }),
                },
                PlayingScene,
            );

            spawned_positions.push(coin_pos);
            coins_spawned += 1;

            if coins_spawned >= MAX_COINS {
                break;
            }
        }
    }

    collectible_spawner.coins_spawned = coins_spawned;
    info!("✅ Spawned {} coins around navigation positions!", coins_spawned);
}



/// Validates a coin position using collision detection
fn is_valid_coin_position(
    position: Vec3,
    spatial_query: &SpatialQuery,
) -> bool {
    // Very permissive validation - just ensure we're not intersecting with too many things
    let coin_radius = 0.2; // Very small collision check
    let check_radius = coin_radius + 0.05; // Minimal buffer
    
    let intersection_filter = SpatialQueryFilter::default()
        .with_mask(LayerMask::ALL);
    
    let intersections = spatial_query.shape_intersections(
        &Collider::sphere(check_radius),
        position,
        Quat::IDENTITY,
        &intersection_filter,
    );
    
    // Very permissive - allow up to 5 intersections
    intersections.len() <= 5
}



// ===== PLUGIN =====

pub struct CollectiblesPlugin;

impl Plugin for CollectiblesPlugin {
    fn build(&self, app: &mut App) {
        app.add_event::<InteractionEvent>()
            .insert_resource(crate::ui::inventory::InventoryVisibilityState::default())
            .init_resource::<CollectibleSpawner>()
            .init_resource::<PlayerMovementTracker>()
            .init_resource::<NavigationBasedSpawner>()
            .add_systems(
                Update,
                (
                    auto_collect_nearby_interactables,
                    update_floating_items,
                    rotate_collectibles,
                    crate::ui::inventory::add_item_to_inventory,
                    crate::ui::inventory::toggle_inventory_visibility,
                    crate::ui::inventory::adjust_inventory_for_dialogs,
                    load_navigation_data_system,
                    spawn_navigation_based_collectibles_system,
                    track_player_movement,
                    // track_player_navigation,
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
    let model_handle = assets.coin.clone();

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



#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NavigationData {
    pub session_start: String,
    pub positions: Vec<NavigationPoint>,
    pub statistics: NavigationStats,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NavigationPoint {
    pub timestamp: f64,
    pub position: [f32; 3],
    pub session_time: f32,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NavigationStats {
    pub total_points: usize,
    pub session_duration: f32,
    pub min_bounds: [f32; 3],
    pub max_bounds: [f32; 3],
    pub average_position: [f32; 3],
}

impl Default for NavigationData {
    fn default() -> Self {
        use std::time::{SystemTime, UNIX_EPOCH};
        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        Self {
            session_start: format!("{}", timestamp),
            positions: Vec::new(),
            statistics: NavigationStats {
                total_points: 0,
                session_duration: 0.0,
                min_bounds: [f32::INFINITY; 3],
                max_bounds: [f32::NEG_INFINITY; 3],
                average_position: [0.0; 3],
            },
        }
    }
}

// Replace the surface-based spawning with navigation-based spawning
#[derive(Resource)]
pub struct NavigationBasedSpawner {
    pub nav_positions: Vec<Vec3>,
    pub spawn_radius: f32,
    pub spawn_probability: f32,
    pub min_distance_between_coins: f32,
    pub loaded: bool,
}

impl Default for NavigationBasedSpawner {
    fn default() -> Self {
        Self {
            nav_positions: Vec::new(),
            spawn_radius: 8.0,           // Spawn coins within 8 units of nav positions
            spawn_probability: 0.15,     // 15% chance per nav position
            min_distance_between_coins: 4.0, // Minimum 4 units between coins
            loaded: false,
        }
    }
}
