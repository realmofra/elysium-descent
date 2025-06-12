use avian3d::prelude::*;
use bevy::prelude::*;
use bevy_gltf_animation::prelude::*;
use std::sync::Arc;

use super::Screen;
use crate::systems::character_controller::{CharacterController, CharacterControllerPlugin, CharacterControllerBundle, setup_idle_animation};
use crate::systems::collectibles::{CollectiblesPlugin, CollectibleType, spawn_collectible, CollectibleConfig, CollectibleRotation};

// ===== PLUGIN SETUP =====

pub(super) fn plugin(app: &mut App) {
    app.add_systems(OnEnter(Screen::GamePlay), PlayingScene::spawn_environment)
        .add_systems(Update, camera_follow_player)
        .add_systems(OnExit(Screen::GamePlay), despawn_scene::<PlayingScene>)
        .add_plugins(PhysicsPlugins::default())
        // .add_plugins(PhysicsDebugPlugin::default())
        .add_plugins(CharacterControllerPlugin)
        .add_plugins(GltfAnimationPlugin)
        .add_plugins(CollectiblesPlugin)
        .insert_resource(ClearColor(Color::srgb(0.529, 0.808, 0.922))); // Sky blue color
}

// ===== SYSTEMS =====

fn despawn_scene<S: Component>(mut commands: Commands, query: Query<Entity, With<S>>) {
    for entity in &query {
        commands.entity(entity).despawn();
    }
}

fn camera_follow_player(
    player_query: Query<&Transform, With<CharacterController>>,
    mut camera_query: Query<&mut Transform, (With<Camera>, Without<CharacterController>)>,
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
            camera_transform.translation = camera_transform.translation.lerp(
                target_pos,
                (5.0 * time.delta_secs()).min(1.0),
            );
            
            // Make camera look at player
            camera_transform.look_at(player_pos + Vec3::Y * 2.0, Vec3::Y);
        }
    }
}

#[derive(Component)]
struct PlayingScene;

#[derive(Component)]
struct EnvironmentMarker;

// ===== PLAYING SCENE IMPLEMENTATION =====

impl PlayingScene {
    fn spawn_environment(
        mut commands: Commands,
        assets: Res<AssetServer>,
    ) {
        // Set up ambient light
        commands.insert_resource(AmbientLight {
            color: Color::srgb_u8(68, 71, 88),
            brightness: 120.0,
            ..default()
        });

        // Environment (see the `collider_constructors` example for creating colliders from scenes)
        let scene_handle = assets.load("models/environment.glb#Scene0");
        commands.spawn((
            Name::new("Environment"),
            EnvironmentMarker,
            SceneRoot(scene_handle),
            Transform {
                translation: Vec3::new(0.0, -1.5, 0.0),
                rotation: Quat::from_rotation_y(-core::f32::consts::PI * 0.5),
                scale: Vec3::splat(0.05), // Scale environment down
            },
            ColliderConstructorHierarchy::new(ColliderConstructor::TrimeshFromMesh),
            RigidBody::Static,
            //DebugRender::default(),
        ));

        // Add directional light
        commands.spawn((
            Name::new("Directional Light"),
            DirectionalLight {
                illuminance: 80_000.0, // bright midday sun
                shadows_enabled: true,
                ..default()
            },
            Transform::from_rotation(Quat::from_euler(
                EulerRot::XYZ,
                -std::f32::consts::FRAC_PI_3,
                std::f32::consts::FRAC_PI_4,
                0.0,
            )),
        ));

        // Add player
        commands.spawn((
            Name::new("Player"),
            GltfSceneRoot::new(assets.load("models/player.glb")),
            Transform {
                translation: Vec3::new(0.0, 2.0, 0.0),
                scale: Vec3::splat(4.0),
                ..default()
            },
            CharacterControllerBundle::new(),
            Friction::new(0.5),
            Restitution::new(0.0),
            GravityScale(1.0),
            // DebugRender::default(),
        )).observe(setup_idle_animation);

        // Define collectible configurations
        let collectible_configs = vec![
            CollectibleConfig {
                position: Vec3::new(0.0, 2.0, 60.0),
                collectible_type: CollectibleType::Pumpkin,
                scale: 1.0,
                rotation: Some(CollectibleRotation::new(true, false, 1.5)), // Spinning counter-clockwise at 1.5 rad/s
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
            CollectibleConfig {
                position: Vec3::new(5.0, 2.0, 60.0),
                collectible_type: CollectibleType::Coconut,
                scale: 1.0,
                rotation: None, // No rotation
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
            CollectibleConfig {
                position: Vec3::new(10.0, 2.0, 60.0),
                collectible_type: CollectibleType::Mushroom,
                scale: 1.0,
                rotation: Some(CollectibleRotation::new(true, true, 3.0)), // Fast clockwise spin
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
            CollectibleConfig {
                position: Vec3::new(15.0, 2.0, 60.0),
                collectible_type: CollectibleType::Pumpkin,
                scale: 1.0,
                rotation: Some(CollectibleRotation::new(true, false, 1.0)), // Slow counter-clockwise spin
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
            CollectibleConfig {
                position: Vec3::new(20.0, 2.0, 60.0),
                collectible_type: CollectibleType::Coconut,
                scale: 1.0,
                rotation: Some(CollectibleRotation::new(true, true, 2.5)), // Medium-fast clockwise spin
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
            CollectibleConfig {
                position: Vec3::new(25.0, 2.0, 60.0),
                collectible_type: CollectibleType::Mushroom,
                scale: 1.0,
                rotation: None, // No rotation
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
            CollectibleConfig {
                position: Vec3::new(30.0, 2.0, 60.0),
                collectible_type: CollectibleType::Pumpkin,
                scale: 1.0,
                rotation: Some(CollectibleRotation::new(true, false, 2.0)), // Medium counter-clockwise spin
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
            CollectibleConfig {
                position: Vec3::new(35.0, 2.0, 60.0),
                collectible_type: CollectibleType::Coconut,
                scale: 1.0,
                rotation: Some(CollectibleRotation::new(true, true, 1.0)), // Slow clockwise spin
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
            CollectibleConfig {
                position: Vec3::new(40.0, 2.0, 60.0),
                collectible_type: CollectibleType::Mushroom,
                scale: 1.0,
                rotation: Some(CollectibleRotation::new(true, false, 3.0)), // Fast counter-clockwise spin
                on_collect: Arc::new(|commands, entity| {
                    commands.entity(entity).despawn();
                }),
            },
        ];

        // Spawn all collectibles from configurations
        for config in collectible_configs {
            spawn_collectible(&mut commands, &assets, config);
        }

        // Add camera
        commands.spawn((
            Name::new("Camera"),
            Camera3d::default(),
            Camera {
                order: 1,
                ..default()
            },
            Transform::from_xyz(0.0, 4.0, -12.0).looking_at(Vec3::new(0.0, 2.0, 0.0), Vec3::Y),
        ));
    }
}