use avian3d::prelude::*;
use bevy::prelude::*;
use bevy_gltf_animation::prelude::*;

use super::{Screen, despawn_scene};
use crate::assets::{FontAssets, ModelAssets, UiAssets};
use crate::keybinding;
use crate::systems::character_controller::{
    CharacterController, CharacterControllerBundle, CharacterControllerPlugin, setup_idle_animation,
};
use crate::systems::collectibles::{
    CollectibleType, CollectiblesPlugin, collectible_spawner_system,
};
use crate::ui::dialog::{DialogPlugin, spawn_dialog, DialogConfig};
use crate::ui::inventory::spawn_inventory_ui;
use crate::ui::widgets::{HudPosition, player_hud_widget};
use crate::ui::dialog::DialogPosition::BottomCenter;
use bevy_enhanced_input::prelude::*;

// ===== PLUGIN SETUP =====

pub(super) fn plugin(app: &mut App) {
    app.add_systems(
        OnEnter(Screen::GamePlay),
        (
            PlayingScene::spawn_environment,
            set_gameplay_clear_color,
        ),
    )
    .add_systems(
        Update,
        camera_follow_player.run_if(in_state(Screen::GamePlay)),
    )
    .add_systems(
        OnExit(Screen::GamePlay),
        (despawn_scene::<PlayingScene>, despawn_gameplay_hud),
    )
    .add_plugins(PhysicsPlugins::default())
    // .add_plugins(PhysicsDebugPlugin::default())
    .add_plugins(CharacterControllerPlugin)
    .add_plugins(GltfAnimationPlugin)
    .add_plugins(CollectiblesPlugin);
}

// ===== SYSTEMS =====

fn set_gameplay_clear_color(mut commands: Commands) {
    commands.insert_resource(ClearColor(Color::srgb(0.529, 0.808, 0.922))); // Sky blue color
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
    fn spawn_environment(
        mut commands: Commands,
        assets: Res<ModelAssets>,
        font_assets: Res<FontAssets>,
        ui_assets: Res<UiAssets>,
        windows: Query<&Window>,
    ) {
        // Set up ambient light
        commands.insert_resource(AmbientLight {
            color: Color::srgb_u8(68, 71, 88),
            brightness: 120.0,
            ..default()
        });

        // Environment (see the `collider_constructors` example for creating colliders from scenes)
        let scene_handle = assets.environment.clone();
        commands.spawn((
            Name::new("Environment"),
            EnvironmentMarker,
            PlayingScene, // Add scene marker to ensure cleanup
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
            PlayingScene, // Add scene marker to ensure cleanup
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
                // Add enhanced input actions for this player
                Actions::<keybinding::Player>::default(),
                PlayingScene, // Add scene marker to ensure cleanup
                              // DebugRender::default(),
            ))
            .observe(setup_idle_animation);

        // Spawn collectibles using imported array
        // (Leave a comment for where dynamic spawning will be handled.)

        // Add camera
        commands.spawn((
            Name::new("Gameplay Camera"),
            Camera3d::default(),
            Camera {
                order: 1,
                ..default()
            },
            Transform::from_xyz(0.0, 4.0, -12.0).looking_at(Vec3::new(0.0, 2.0, 0.0), Vec3::Y),
            PlayingScene, // Add scene marker to ensure cleanup
        ));

        spawn_inventory_ui::<PlayingScene>(&mut commands);
        spawn_player_hud(&mut commands, &font_assets, &ui_assets);
    }
}
