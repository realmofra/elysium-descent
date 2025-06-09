use avian3d::prelude::*;
use bevy::prelude::*;
use bevy_gltf_animation::prelude::*;

use super::Screen;
use crate::systems::character_controller::{CharacterController, CharacterControllerPlugin, TrimeshCharacterControllerBundle};

// ===== PLUGIN SETUP =====

pub(super) fn plugin(app: &mut App) {
    app.add_systems(OnEnter(Screen::GamePlay), PlayingScene::spawn_environment)
        .add_systems(Update, (
            camera_follow_player,
            update_animations,
        ))
        .add_systems(OnExit(Screen::GamePlay), despawn_scene::<PlayingScene>)
        .add_plugins(PhysicsPlugins::default())
        // .add_plugins(PhysicsDebugPlugin::default())
        .add_plugins(CharacterControllerPlugin)
        .add_plugins(GltfAnimationPlugin)
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

// ===== ANIMATION SYSTEMS =====

fn update_animations(
    mut players: Query<(&mut GltfAnimations, &LinearVelocity, &mut AnimationState), With<CharacterController>>,
    mut animation_players: Query<&mut AnimationPlayer>,
) {
    for (mut gltf_animations, velocity, mut anim_state) in players.iter_mut() {
        let mut player = animation_players.get_mut(gltf_animations.animation_player).unwrap();
        // Only check horizontal movement (X and Z components)
        let horizontal_velocity = Vec2::new(velocity.0.x, velocity.0.z);
        let is_moving = horizontal_velocity.length() > 0.1;
        
        // Only change animation if movement state changed
        if is_moving != anim_state.is_moving {
            info!("Player velocity: {:?}, Horizontal velocity: {:?}, Is moving: {}", velocity.0, horizontal_velocity, is_moving);
            let animation_index = if is_moving { 4 } else { 2 };
            let animation = gltf_animations.get_by_number(animation_index).unwrap();
            player.stop_all();
            player.play(animation).repeat();
            anim_state.is_moving = is_moving;
        }
    }
}

fn idle(
    trigger: Trigger<OnAdd, GltfAnimations>,
    mut commands: Commands,
    mut players: Query<&mut GltfAnimations>,
    mut animation_players: Query<&mut AnimationPlayer>,
) {
    let Ok(mut gltf_animations) = players.get_mut(trigger.target()) else {
        return;
    };
    let mut player = animation_players.get_mut(gltf_animations.animation_player).unwrap();
    let animation = gltf_animations.get_by_number(2).unwrap();
    player.stop_all();
    player.play(animation).repeat();
    
    // Add AnimationState component
    commands.entity(trigger.target()).insert(AnimationState { is_moving: false });
}

#[derive(Component)]
struct AnimationState {
    is_moving: bool,
}

// ===== RESOURCES & COMPONENTS =====

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
            TrimeshCharacterControllerBundle::new(),
            Friction::new(0.5),
            Restitution::new(0.0),
            GravityScale(1.0),
            AnimationState { is_moving: false },
            // DebugRender::default(),
        )).observe(idle);

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