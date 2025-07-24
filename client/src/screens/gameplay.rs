use avian3d::prelude::*;
use bevy::prelude::*;
use bevy_gltf_animation::prelude::*;
use rand::prelude::*;

use super::{Screen, despawn_scene};
use super::pregame_loading::EnvironmentPreload;
use crate::assets::{FontAssets, ModelAssets, UiAssets};
use crate::keybinding;
use crate::systems::character_controller::{
    CharacterController, CharacterControllerBundle, CharacterControllerPlugin, setup_idle_animation,
};
use crate::systems::collectibles::{CollectiblesPlugin, NavigationBasedSpawner, CollectibleSpawner, CoinStreamingManager};
use crate::ui::dialog::DialogPlugin;
use crate::ui::inventory::spawn_inventory_ui;
use crate::ui::widgets::{HudPosition, player_hud_widget};
use bevy_enhanced_input::prelude::*;

// ===== PLUGIN SETUP =====

pub(super) fn plugin(app: &mut App) {
    app.add_systems(
        OnEnter(Screen::GamePlay),
        (
            reveal_preloaded_environment,
            debug_streaming_manager_state,
            PlayingScene::spawn_player_and_camera,
            set_gameplay_clear_color,
        ),
    )
    .add_systems(
        Update,
        (
            camera_follow_player,
            // Fallback systems that run if preloaded entities weren't found
            fallback_spawn_environment,
            fallback_spawn_collectibles,
        ).run_if(in_state(Screen::GamePlay)),
    )
    .add_systems(
        OnExit(Screen::GamePlay),
        (despawn_scene::<PlayingScene>, despawn_gameplay_hud),
    )
    .add_plugins(PhysicsPlugins::default())
    // .add_plugins(PhysicsDebugPlugin::default())
    .add_plugins(CharacterControllerPlugin)
    .add_plugins(GltfAnimationPlugin)
    .add_plugins(CollectiblesPlugin)
    .add_plugins(DialogPlugin);
}

// ===== SYSTEMS =====

fn set_gameplay_clear_color(mut commands: Commands) {
    commands.insert_resource(ClearColor(Color::srgb(0.529, 0.808, 0.922))); // Sky blue color
}

fn debug_streaming_manager_state(streaming_manager: Res<CoinStreamingManager>) {
    info!("🔍 GamePlay Debug: CoinStreamingManager has {} stored positions when entering GamePlay", 
          streaming_manager.positions.len());
    if streaming_manager.positions.is_empty() {
        warn!("⚠️ No coin positions found when entering GamePlay! Loading may have failed.");
    } else {
        info!("✅ Coin positions successfully preserved from PreGameLoading");
        
        // Show first few positions for debugging
        let sample_count = 5.min(streaming_manager.positions.len());
        for i in 0..sample_count {
            info!("  Sample coin {}: {:?}", i, streaming_manager.positions[i]);
        }
        
        info!("  Total coin positions: {}", streaming_manager.positions.len());
        info!("  Player spawns at: (0.0, 2.0, 0.0)");
        info!("  Using ACTUAL navigation data from nav.json");
    }
}

fn camera_follow_player(
    player_query: Query<&Transform, With<CharacterController>>,
    mut camera_query: Query<
        &mut Transform,
        (
            With<Camera3d>,
            With<PlayingScene>,
            Without<CharacterController>,
        ),
    >,
    time: Res<Time>,
) {
    if let Ok(player_transform) = player_query.single() {
        for mut camera_transform in camera_query.iter_mut() {
            let player_pos = player_transform.translation;
            let player_rotation = player_transform.rotation;

            // Calculate camera position behind player (inverted Z)
            let camera_offset = player_rotation * Vec3::new(0.0, 4.0, -12.0);
            let target_pos = player_pos + camera_offset;

            // Smoothly move camera to new position
            camera_transform.translation = camera_transform
                .translation
                .lerp(target_pos, (5.0 * time.delta_secs()).min(1.0));

            // Make camera look at player
            camera_transform.look_at(player_pos + Vec3::Y * 2.0, Vec3::Y);
        }
    }
}

#[derive(Component, Default, Clone)]
pub struct PlayingScene;

#[derive(Component)]
struct EnvironmentMarker;

#[derive(Component)]
struct GameplayHud;

fn spawn_player_hud(
    commands: &mut Commands,
    font_assets: &Res<FontAssets>,
    ui_assets: &Res<UiAssets>,
) {
    // Example values, replace with actual player data
    let avatar = ui_assets.player_avatar.clone();
    let name = "0XJEHU";
    let level = 2;
    let health = (105, 115);
    let xp = (80, 100);
    let font = font_assets.rajdhani_bold.clone();

    commands.spawn((
        player_hud_widget(avatar, name, level, health, xp, font, HudPosition::Left),
        GameplayHud,
    ));
}

fn despawn_gameplay_hud(mut commands: Commands, query: Query<Entity, With<GameplayHud>>) {
    for entity in &query {
        commands.entity(entity).despawn();
    }
}

// ===== PLAYING SCENE IMPLEMENTATION =====

impl PlayingScene {
    fn spawn_player_and_camera(
        mut commands: Commands,
        assets: Res<ModelAssets>,
        font_assets: Res<FontAssets>,
        ui_assets: Res<UiAssets>,
        windows: Query<&Window>,
    ) {
        info!("👤 Spawning player and camera...");

        // Add directional light (if not already added by preload)
        commands.spawn((
            Name::new("Directional Light"),
            DirectionalLight {
                illuminance: 80_000.0,
                shadows_enabled: true,
                ..default()
            },
            Transform::from_rotation(Quat::from_euler(
                EulerRot::XYZ,
                -std::f32::consts::FRAC_PI_3,
                std::f32::consts::FRAC_PI_4,
                0.0,
            )),
            PlayingScene,
        ));

        // Add player
        commands
            .spawn((
                Name::new("Player"),
                GltfSceneRoot::new(assets.player.clone()),
                Transform {
                    translation: Vec3::new(0.0, 2.0, 0.0),
                    scale: Vec3::splat(4.0),
                    ..default()
                },
                CharacterControllerBundle::new(),
                Friction::new(0.5),
                Restitution::new(0.0),
                GravityScale(1.0),
                Actions::<keybinding::Player>::default(),
                PlayingScene,
            ))
            .observe(setup_idle_animation);

        // Add camera
        commands.spawn((
            Name::new("Gameplay Camera"),
            Camera3d::default(),
            Camera {
                order: 1,
                ..default()
            },
            Transform::from_xyz(0.0, 4.0, -12.0).looking_at(Vec3::new(0.0, 2.0, 0.0), Vec3::Y),
            PlayingScene,
        ));

        spawn_inventory_ui::<PlayingScene>(&mut commands);
        spawn_player_hud(&mut commands, &font_assets, &ui_assets);
        
        // Spawn the 'Press E to Open' dialog for Mystery Boxes
        use crate::ui::dialog::{spawn_dialog, DialogConfig, DialogPosition};
        spawn_dialog(
            &mut commands,
            &font_assets,
            windows,
            DialogConfig {
                text: "Press E to Open".to_string(),
                position: DialogPosition::BottomCenter { bottom_margin: 4.0 },
                ..Default::default()
            },
            PlayingScene,
        );

        info!("✅ Player and camera spawned");
    }
}

fn reveal_preloaded_environment(
    mut commands: Commands,
    environment_query: Query<Entity, With<EnvironmentPreload>>,
) {
    info!("🌍 Revealing preloaded environment...");
    info!("🔍 Found {} environment entities with EnvironmentPreload marker", environment_query.iter().count());
    
    let mut revealed_count = 0;
    for entity in environment_query.iter() {
        commands.entity(entity)
            .insert(Visibility::Visible)
            .insert(PlayingScene);
        revealed_count += 1;
        info!("✅ Environment entity {:?} revealed and marked with PlayingScene", entity);
    }
    
    if revealed_count == 0 {
        warn!("⚠️ No preloaded environment entities found! Environment may not have been created during loading.");
    } else {
        info!("✅ Revealed {} environment entities", revealed_count);
    }
}

// Removed: No longer using preloaded collectibles - using streaming system instead

#[derive(Resource, Default)]
struct FallbackSpawned {
    environment: bool,
    collectibles: bool,
}

fn fallback_spawn_environment(
    mut commands: Commands,
    assets: Option<Res<ModelAssets>>,
    environment_query: Query<Entity, With<PlayingScene>>,
    environment_preload_query: Query<Entity, With<EnvironmentPreload>>,
    mut fallback_spawned: Local<bool>,
) {
    // Only run once, and only if no environment entities exist (neither preloaded nor PlayingScene)
    if *fallback_spawned || !environment_query.is_empty() || !environment_preload_query.is_empty() {
        return;
    }

    if let Some(assets) = assets {
        warn!("🚨 Fallback: Spawning environment directly (preload failed)");
        
        // Set up ambient light
        commands.insert_resource(AmbientLight {
            color: Color::srgb_u8(68, 71, 88),
            brightness: 120.0,
            ..default()
        });

        // Environment
        commands.spawn((
            Name::new("Fallback Environment"),
            SceneRoot(assets.environment.clone()),
            Transform {
                translation: Vec3::new(0.0, -1.5, 0.0),
                rotation: Quat::from_rotation_y(-core::f32::consts::PI * 0.5),
                scale: Vec3::splat(0.05),
            },
            ColliderConstructorHierarchy::new(ColliderConstructor::TrimeshFromMesh),
            RigidBody::Static,
            PlayingScene,
        ));

        *fallback_spawned = true;
        info!("✅ Fallback environment spawned");
    }
}

fn fallback_spawn_collectibles(
    mut commands: Commands,
    assets: Option<Res<ModelAssets>>,
    nav_spawner: Option<Res<NavigationBasedSpawner>>,
    mut collectible_spawner: ResMut<CollectibleSpawner>,
    collectible_query: Query<Entity, With<crate::systems::collectibles::Collectible>>,
    spatial_query: SpatialQuery,
    mut fallback_spawned: Local<bool>,
) {
    // Only run once, and only if no collectible entities exist
    if *fallback_spawned || !collectible_query.is_empty() || collectible_spawner.coins_spawned > 0 {
        return;
    }

    if let (Some(assets), Some(nav_spawner)) = (assets, nav_spawner) {
        if nav_spawner.loaded {
            warn!("🚨 Fallback: Spawning collectibles directly (preload failed)");
            
            let mut rng = rand::rng();
            let mut spawned_positions = Vec::new();
            let mut coins_spawned = 0;
            const MAX_COINS: usize = 50;

            for nav_pos in &nav_spawner.nav_positions {
                if rng.random::<f32>() > nav_spawner.spawn_probability {
                    continue;
                }

                let angle = rng.random::<f32>() * std::f32::consts::TAU;
                let distance = rng.random::<f32>() * 8.0; // Use reasonable default radius
                let offset = Vec3::new(
                    angle.cos() * distance,
                    0.0,
                    angle.sin() * distance,
                );
                let potential_pos = *nav_pos + offset;

                let too_close = spawned_positions.iter().any(|&other_pos: &Vec3| {
                    potential_pos.distance(other_pos) < 4.0 // Use reasonable default min distance
                });

                if too_close {
                    continue;
                }

                let coin_y = if potential_pos.y + 2.5 <= -1.5 {
                    1.0
                } else {
                    potential_pos.y + 2.5
                };
                let coin_pos = Vec3::new(potential_pos.x, coin_y, potential_pos.z);
                
                spawn_fallback_collectible(
                    &mut commands,
                    &assets,
                    coin_pos,
                );

                spawned_positions.push(coin_pos);
                coins_spawned += 1;

                if coins_spawned >= MAX_COINS {
                    break;
                }
            }

            collectible_spawner.coins_spawned = coins_spawned;
            *fallback_spawned = true;
            info!("✅ Fallback spawned {} collectibles", coins_spawned);
        }
    }
}

fn spawn_fallback_collectible(
    commands: &mut Commands,
    assets: &Res<ModelAssets>,
    position: Vec3,
) {
    use crate::systems::collectibles::{
        Collectible, CollectibleType, FloatingItem, CollectibleRotation, 
        Sensor, Interactable
    };

    commands.spawn((
        Name::new("Fallback Coin"),
        SceneRoot(assets.coin.clone()),
        Transform {
            translation: position,
            scale: Vec3::splat(0.75),
            ..default()
        },
        Collider::sphere(0.5),
        RigidBody::Kinematic,
        Visibility::Visible,
        Collectible,
        CollectibleType::Coin,
        FloatingItem {
            base_height: position.y,
            hover_amplitude: 0.2,
            hover_speed: 2.0,
        },
        CollectibleRotation {
            enabled: true,
            clockwise: true,
            speed: 1.0,
        },
        Sensor,
        Interactable {
            interaction_radius: 4.0,
        },
        PlayingScene,
    ));
}
