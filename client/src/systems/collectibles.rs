use crate::assets::ModelAssets;
use avian3d::prelude::*;
use bevy::prelude::*;
use serde::{Deserialize, Serialize};
use std::fs;

use crate::screens::Screen;
use crate::systems::character_controller::CharacterController;
use crate::systems::dojo::PickupItemEvent;
use rand::prelude::*;
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

// Pre-spawn system for collectibles
#[derive(Resource)]
pub struct EnvironmentMap {
    pub valid_positions: Vec<Vec3>,
    pub scan_complete: bool,
    pub coins_placed: bool,
}

impl Default for EnvironmentMap {
    fn default() -> Self {
        Self {
            valid_positions: Vec::new(),
            scan_complete: false,
            coins_placed: false,
        }
    }
}

// Configuration for environment scanning
#[derive(Resource)]
pub struct ScanConfig {
    pub scan_bounds: (Vec3, Vec3), // (min, max) bounds for scanning
    pub min_surface_size: f32,      // Minimum size of flat surface required
    pub surface_tolerance: f32,     // Height tolerance for "flat" surface
    pub player_height: f32,         // Total player height for coin placement
    pub min_spacing: f32,           // Minimum distance between coins
}

impl Default for ScanConfig {
    fn default() -> Self {
        Self {
            scan_bounds: (Vec3::new(-100.0, -10.0, -100.0), Vec3::new(100.0, 30.0, 100.0)),
            min_surface_size: 6.0,        // Increased search radius for flat areas
            surface_tolerance: 0.5,       // More lenient height tolerance
            player_height: 0.9,           // Player capsule total height (0.5 + 2*0.2)
            min_spacing: 3.0,             // Increased spacing between coins
        }
    }
}

#[derive(Debug, Clone)]
pub struct FlatSurface {
    pub center: Vec3,
    pub size: f32,
    pub height: f32,
}

/// Scans the environment to find flat surfaces suitable for coin placement
fn environment_scanner_system(
    mut env_map: ResMut<EnvironmentMap>,
    scan_config: Res<ScanConfig>,
    spatial_query: SpatialQuery,
) {
    if env_map.scan_complete {
        return;
    }
    
    info!("🔍 Starting comprehensive flat surface analysis...");
    info!("📊 Target: 10x10 flat surface tops detection");
    
    let (min_bounds, max_bounds) = scan_config.scan_bounds;
    let spacing = 1.0; // Fine-grained scanning for accurate surface detection
    
    let mut surface_points = Vec::new();
    let mut scan_count = 0;
    
    // First pass: find all ground points with detailed logging
    let mut x = min_bounds.x;
    while x <= max_bounds.x {
        let mut z = min_bounds.z;
        while z <= max_bounds.z {
            scan_count += 1;
            
            if let Some(ground_pos) = find_ground_position(Vec3::new(x, max_bounds.y, z), &spatial_query) {
                surface_points.push(ground_pos);
                
                // Debug every 1000th successful ground detection
                if surface_points.len() % 1000 == 0 {
                    info!("Ground point #{}: {:?}", surface_points.len(), ground_pos);
                }
            }
            
            z += spacing;
        }
        x += spacing;
        
        // Debug progress every 20% of X range (reduced logging)
        if ((x - min_bounds.x) / (max_bounds.x - min_bounds.x) * 5.0) as i32 % 1 == 0 {
            info!("Scan progress: {:.0}%, found {} ground points so far", 
                (x - min_bounds.x) / (max_bounds.x - min_bounds.x) * 100.0, 
                surface_points.len()
            );
        }
    }
    
    info!("📍 Found {} ground points from {} scan positions", surface_points.len(), scan_count);
    
    // FALLBACK: If we found very few ground points, create a simple grid at player level
    if surface_points.len() < 100 {
        info!("⚠️ Ground detection failed, using fallback placement strategy...");
        
        let player_level = 0.0; // Assume ground level
        let fallback_spacing = 1.0; // Dense fallback grid
        
        let mut fallback_x = min_bounds.x + 10.0; // Start closer to center
        while fallback_x <= max_bounds.x - 10.0 {
            let mut fallback_z = min_bounds.z + 10.0;
            while fallback_z <= max_bounds.z - 10.0 {
                surface_points.push(Vec3::new(fallback_x, player_level, fallback_z));
                fallback_z += fallback_spacing;
            }
            fallback_x += fallback_spacing;
        }
        
        info!("🔄 Generated {} fallback positions", surface_points.len());
    }
    
    // Comprehensive flat surface analysis
    let flat_surfaces_analysis = analyze_flat_surfaces_comprehensive(&surface_points);
    info!("🏔️ FLAT SURFACE ANALYSIS COMPLETE:");
    info!("   📏 10x10+ surfaces found: {}", flat_surfaces_analysis.large_surfaces);
    info!("   📐 5x5+ surfaces found: {}", flat_surfaces_analysis.medium_surfaces); 
    info!("   📑 3x3+ surfaces found: {}", flat_surfaces_analysis.small_surfaces);
    info!("   📊 Total surface area: {:.1} square units", flat_surfaces_analysis.total_area);
    
    // Create surfaces for coin placement (use medium criteria for actual placement)
    let flat_surfaces = identify_flat_surfaces_for_coins(&surface_points, &scan_config);
    info!("🪙 Surfaces suitable for coins: {}", flat_surfaces.len());
    
    // Third pass: place coins on suitable surfaces
    let mut valid_positions = Vec::new();
    let coin_height = scan_config.player_height / 2.0; // Half player height
    
    for surface in &flat_surfaces {
        let coin_positions = generate_coin_positions_on_surface(surface, coin_height, &scan_config, &spatial_query);
        valid_positions.extend(coin_positions);
    }
    
    env_map.valid_positions = valid_positions;
    env_map.scan_complete = true;
    
    info!("✅ Environment scan complete!");
    info!("📊 Final results: {} surfaces analyzed, {} coin locations generated", 
        flat_surfaces.len(), env_map.valid_positions.len());
}

#[derive(Debug)]
struct SurfaceAnalysis {
    large_surfaces: usize,  // 10x10+
    medium_surfaces: usize, // 5x5+
    small_surfaces: usize,  // 3x3+
    total_area: f32,
}

/// Comprehensive analysis of flat surfaces in the environment
fn analyze_flat_surfaces_comprehensive(points: &[Vec3]) -> SurfaceAnalysis {
    let mut analysis = SurfaceAnalysis {
        large_surfaces: 0,
        medium_surfaces: 0,
        small_surfaces: 0,
        total_area: 0.0,
    };
    
    if points.is_empty() {
        return analysis;
    }
    
    let mut used_points = vec![false; points.len()];
    let tolerance = 0.5; // Height tolerance for flat surfaces
    
    info!("🔍 Analyzing {} points for flat surfaces of different sizes...", points.len());
    
    for (i, &center_point) in points.iter().enumerate() {
        if used_points[i] {
            continue;
        }
        
        // Find all nearby points within height tolerance
        let mut surface_points = vec![center_point];
        let mut surface_indices = vec![i];
        
        for (j, &other_point) in points.iter().enumerate() {
            if i == j || used_points[j] {
                continue;
            }
            
            let distance = center_point.distance(other_point);
            let height_diff = (center_point.y - other_point.y).abs();
            
            // Check if point is within reasonable distance and height tolerance
            if distance <= 15.0 && height_diff <= tolerance {
                surface_points.push(other_point);
                surface_indices.push(j);
            }
        }
        
        // Analyze surface if we have enough points
        if surface_points.len() >= 9 { // At least 3x3 worth of points
            // Calculate surface dimensions
            let min_x = surface_points.iter().map(|p| p.x).fold(f32::INFINITY, f32::min);
            let max_x = surface_points.iter().map(|p| p.x).fold(f32::NEG_INFINITY, f32::max);
            let min_z = surface_points.iter().map(|p| p.z).fold(f32::INFINITY, f32::min);
            let max_z = surface_points.iter().map(|p| p.z).fold(f32::NEG_INFINITY, f32::max);
            
            let width = max_x - min_x;
            let depth = max_z - min_z;
            let size = width.min(depth);
            let area = width * depth;
            
            analysis.total_area += area;
            
            // Categorize surface by size
            if size >= 10.0 {
                analysis.large_surfaces += 1;
                info!("🏟️ LARGE surface found: {:.1}x{:.1} at height {:.1} ({} points)", 
                    width, depth, center_point.y, surface_points.len());
            } else if size >= 5.0 {
                analysis.medium_surfaces += 1;
                info!("🏘️ Medium surface found: {:.1}x{:.1} at height {:.1} ({} points)", 
                    width, depth, center_point.y, surface_points.len());
            } else if size >= 3.0 {
                analysis.small_surfaces += 1;
                info!("🏠 Small surface found: {:.1}x{:.1} at height {:.1} ({} points)", 
                    width, depth, center_point.y, surface_points.len());
            }
            
            // Mark points as used
            for &idx in &surface_indices {
                used_points[idx] = true;
            }
        }
    }
    
    analysis
}

/// Identifies flat surfaces suitable for coin placement (less strict than analysis)
fn identify_flat_surfaces_for_coins(points: &[Vec3], config: &ScanConfig) -> Vec<FlatSurface> {
    let mut surfaces = Vec::new();
    let mut used_points = vec![false; points.len()];
    
    info!("🪙 Analyzing surfaces for coin placement (minimum 3x3 areas)...");
    
    for (i, &center_point) in points.iter().enumerate() {
        if used_points[i] {
            continue;
        }
        
        // Find nearby points within surface tolerance
        let mut surface_points = vec![center_point];
        let mut surface_indices = vec![i];
        
        for (j, &other_point) in points.iter().enumerate() {
            if i == j || used_points[j] {
                continue;
            }
            
            let distance = center_point.distance(other_point);
            let height_diff = (center_point.y - other_point.y).abs();
            
            // Check if point is within surface area and height tolerance  
            if distance <= config.min_surface_size && height_diff <= config.surface_tolerance {
                surface_points.push(other_point);
                surface_indices.push(j);
            }
        }
        
        // Check if we have enough points for a valid surface
        if surface_points.len() >= 4 { // Reduced from 9 to 4 points minimum
            // Calculate surface properties
            let avg_height = surface_points.iter().map(|p| p.y).sum::<f32>() / surface_points.len() as f32;
            let min_x = surface_points.iter().map(|p| p.x).fold(f32::INFINITY, f32::min);
            let max_x = surface_points.iter().map(|p| p.x).fold(f32::NEG_INFINITY, f32::max);
            let min_z = surface_points.iter().map(|p| p.z).fold(f32::INFINITY, f32::min);
            let max_z = surface_points.iter().map(|p| p.z).fold(f32::NEG_INFINITY, f32::max);
            
            let size = ((max_x - min_x).max(max_z - min_z)).max(2.0); // Minimum 2x2 size
            let surface_center = Vec3::new((min_x + max_x) / 2.0, avg_height, (min_z + max_z) / 2.0);
            
            info!("✅ Coin surface: center={:?}, size={:.1}, points={}", surface_center, size, surface_points.len());
            
            surfaces.push(FlatSurface {
                center: surface_center,
                size,
                height: avg_height,
            });
            
            // Mark points as used
            for &idx in &surface_indices {
                used_points[idx] = true;
            }
        } else if surface_points.len() > 1 {
            info!("❌ Surface candidate rejected: {} points (need 4+)", surface_points.len());
        }
    }
    
    info!("🏔️ Coin placement surfaces: {} identified", surfaces.len());
    surfaces
}

/// Generates coin positions on a flat surface
fn generate_coin_positions_on_surface(
    surface: &FlatSurface,
    coin_height: f32,
    config: &ScanConfig,
    spatial_query: &SpatialQuery,
) -> Vec<Vec3> {
    let mut positions: Vec<Vec3> = Vec::new();
    let spacing = config.min_spacing;
    let half_size = surface.size / 2.0;
    
    // Generate a grid of potential positions on the surface
    let mut x = surface.center.x - half_size + spacing;
    while x <= surface.center.x + half_size - spacing {
        let mut z = surface.center.z - half_size + spacing;
        while z <= surface.center.z + half_size - spacing {
            let coin_position = Vec3::new(x, surface.height + coin_height, z);
            
            // Validate the position
            if is_valid_coin_position(coin_position, spatial_query) {
                // Check spacing from existing positions
                let too_close = positions.iter().any(|existing| {
                    existing.distance(coin_position) < spacing
                });
                
                if !too_close {
                    positions.push(coin_position);
                }
            }
            
            z += spacing;
        }
        x += spacing;
    }
    
    // Limit coins per surface to avoid overcrowding
    if positions.len() > 10 { // Increased from 5 to 10
        positions.truncate(10);
    }
    
    if !positions.is_empty() {
        info!("🪙 Surface coins: {} positions on {:.1}x{:.1} surface at height {:.1}", 
            positions.len(), surface.size, surface.size, surface.height);
    }
    
    positions
}

/// Pre-spawns all collectibles at game start based on environment scan
fn pre_spawn_collectibles_system(
    mut commands: Commands,
    mut env_map: ResMut<EnvironmentMap>,
    mut spawner: ResMut<CollectibleSpawner>,
    assets: Res<ModelAssets>,
) {
    if !env_map.scan_complete || env_map.coins_placed {
        return;
    }
    
    info!("🪙 Pre-spawning collectibles...");
    
    let max_coins = 100.min(env_map.valid_positions.len());
    let mut rng = rand::rng();
    
    // Shuffle positions for variety
    let mut positions = env_map.valid_positions.clone();
    positions.shuffle(&mut rng);
    
    // Spawn coins at the best positions
    for (i, position) in positions.iter().take(max_coins).enumerate() {
        let config = CollectibleConfig {
            position: *position,
            collectible_type: CollectibleType::Coin,
            scale: 1.1,
            rotation: Some(CollectibleRotation {
                enabled: true,
                clockwise: rng.random_bool(0.5),
                speed: rng.random_range(2.0..3.0),
            }),
        };
        
        spawn_collectible(&mut commands, &assets, config, PlayingScene);
        spawner.coins_spawned += 1;
        
        if i % 20 == 0 {
            info!("Spawned {} / {} coins", i + 1, max_coins);
        }
    }
    
    env_map.coins_placed = true;
    info!("✅ Pre-spawned {} coins across the environment!", spawner.coins_spawned);
}

/// Finds the ground position below a given point
fn find_ground_position(
    position: Vec3,
    spatial_query: &SpatialQuery,
) -> Option<Vec3> {
    let ray_start = Vec3::new(position.x, position.y + 50.0, position.z); // Start higher
    let ray_direction = Dir3::NEG_Y;
    let max_distance = 100.0; // Increased scan distance
    
    let ray_filter = SpatialQueryFilter::default()
        .with_mask(LayerMask::ALL);
    
    if let Some(hit) = spatial_query.cast_ray(
        ray_start,
        ray_direction,
        max_distance,
        false,
        &ray_filter,
    ) {
        let hit_point = ray_start + ray_direction.as_vec3() * hit.distance;
        return Some(hit_point);
    }
    
    None
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
            .init_resource::<EnvironmentMap>()
            .init_resource::<ScanConfig>()
            .init_resource::<NavigationTracker>()
            .add_systems(
                Update,
                (
                    auto_collect_nearby_interactables,
                    update_floating_items,
                    rotate_collectibles,
                    crate::ui::inventory::add_item_to_inventory,
                    crate::ui::inventory::toggle_inventory_visibility,
                    crate::ui::inventory::adjust_inventory_for_dialogs,
                    environment_scanner_system,
                    pre_spawn_collectibles_system,
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

// Navigation tracking system - logs player position every 5 seconds
fn track_player_navigation(
    time: Res<Time>,
    mut nav_tracker: ResMut<NavigationTracker>,
    player_query: Query<&Transform, With<CharacterController>>,
) {
    let Ok(player_transform) = player_query.single() else { return; };
    
    nav_tracker.timer.tick(time.delta());
    
    if nav_tracker.timer.just_finished() {
        let position = player_transform.translation;
        let session_time = time.elapsed_secs();
        
        // Create navigation point
        let nav_point = NavigationPoint {
            timestamp: time.elapsed_secs_f64(),
            position: [position.x, position.y, position.z],
            session_time,
        };
        
        // Add to navigation data
        nav_tracker.nav_data.positions.push(nav_point);
        
        // Update statistics
        update_navigation_statistics(&mut nav_tracker.nav_data, position, session_time);
        
        // Save to file
        save_navigation_data(&nav_tracker.nav_data);
        
        // Log the position
        info!("🗺️ Navigation Point #{}: [{:.2}, {:.2}, {:.2}] at {:.1}s", 
            nav_tracker.nav_data.positions.len(),
            position.x, position.y, position.z,
            session_time
        );
    }
}

// Update navigation statistics
fn update_navigation_statistics(nav_data: &mut NavigationData, position: Vec3, session_time: f32) {
    nav_data.statistics.total_points = nav_data.positions.len();
    nav_data.statistics.session_duration = session_time;
    
    // Update bounds
    nav_data.statistics.min_bounds[0] = nav_data.statistics.min_bounds[0].min(position.x);
    nav_data.statistics.min_bounds[1] = nav_data.statistics.min_bounds[1].min(position.y);
    nav_data.statistics.min_bounds[2] = nav_data.statistics.min_bounds[2].min(position.z);
    
    nav_data.statistics.max_bounds[0] = nav_data.statistics.max_bounds[0].max(position.x);
    nav_data.statistics.max_bounds[1] = nav_data.statistics.max_bounds[1].max(position.y);
    nav_data.statistics.max_bounds[2] = nav_data.statistics.max_bounds[2].max(position.z);
    
    // Calculate average position
    if !nav_data.positions.is_empty() {
        let mut sum = [0.0; 3];
        for point in &nav_data.positions {
            sum[0] += point.position[0];
            sum[1] += point.position[1];
            sum[2] += point.position[2];
        }
        let count = nav_data.positions.len() as f32;
        nav_data.statistics.average_position = [
            sum[0] / count,
            sum[1] / count,
            sum[2] / count,
        ];
    }
}

// Save navigation data to nav.json file
fn save_navigation_data(nav_data: &NavigationData) {
    match serde_json::to_string_pretty(nav_data) {
        Ok(json_string) => {
            if let Err(e) = fs::write("nav.json", json_string) {
                error!("Failed to write nav.json: {}", e);
            }
        }
        Err(e) => {
            error!("Failed to serialize navigation data: {}", e);
        }
    }
}

// Navigation tracking system
#[derive(Resource)]
pub struct NavigationTracker {
    pub timer: Timer,
    pub nav_data: NavigationData,
}

impl Default for NavigationTracker {
    fn default() -> Self {
        Self {
            timer: Timer::from_seconds(5.0, TimerMode::Repeating), // Log every 5 seconds
            nav_data: NavigationData::default(),
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
