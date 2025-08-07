use super::{Screen, despawn_scene};
use crate::assets::ModelAssets;
use crate::systems::character_controller::CharacterControllerBundle;
use crate::systems::enemy_ai::{EnemyAIPlugin, EnemyBundle};
use avian3d::prelude::{
    ColliderConstructor, ColliderConstructorHierarchy, CollisionEventsEnabled, Friction,
    GravityScale, Restitution, RigidBody,
};
use bevy::prelude::*;
use bevy_enhanced_input::prelude::Actions;
use bevy_gltf_animation::prelude::{GltfAnimations, GltfSceneRoot};
use crate::constants::animations;

// ===== PLUGIN SETUP =====

pub(super) fn plugin(app: &mut App) {
    app.init_resource::<CombatState>()
        .init_resource::<TurnTimer>()
        .add_systems(
            OnEnter(Screen::FightScene),
            (spawn_fight_scene, despawn_collectibles, initialize_combat),
        )
        .add_systems(
            OnExit(Screen::FightScene),
            (despawn_scene::<FightScene>, reset_combat),
        )
        .add_systems(
            Update,
            (
                handle_fight_input,
                camera_follow_fight_player,
                manage_turn_based_combat,
                handle_enemy_turn,
                handle_player_turn,
                detect_player_attack,
                detect_enemy_attack_finished,
                track_player_turn_time,
            )
                .run_if(in_state(Screen::FightScene)),
        )
        .add_plugins(EnemyAIPlugin);
}

// ===== SYSTEMS =====

fn spawn_fight_scene(
    mut commands: Commands,
    assets: Res<ModelAssets>,
    ui_assets: Res<crate::assets::UiAssets>,
    font_assets: Res<crate::assets::FontAssets>,
) {
    // Set up ambient light (match gameplay)
    commands.insert_resource(AmbientLight {
        color: Color::srgb_u8(68, 71, 88),
        brightness: 120.0,
        ..default()
    });

    // Spawn the dungeon model (match gameplay environment)
    commands.spawn((
        Name::new("Fight Dungeon"),
        SceneRoot(assets.dungeon.clone()),
        Transform {
            translation: Vec3::new(0.0, -1.5, 0.0),
            rotation: Quat::from_rotation_y(-core::f32::consts::PI * 0.5),
            scale: Vec3::splat(7.5),
        },
        ColliderConstructorHierarchy::new(ColliderConstructor::TrimeshFromMesh),
        RigidBody::Static,
        FightScene,
    ));

    // Add directional light (match gameplay)
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
        FightScene,
    ));

    // Spawn the player model (match gameplay)
    commands
        .spawn((
            Name::new("Fight Player"),
            GltfSceneRoot::new(assets.player.clone()),
            Transform {
                translation: Vec3::new(5.0, 2.0, -10.0),
                scale: Vec3::splat(4.0),
                ..default()
            },
            CharacterControllerBundle::new(),
            Friction::new(0.5),
            Restitution::new(0.0),
            GravityScale(1.0),
            CollisionEventsEnabled, // Enable collision events
            Actions::<crate::keybinding::Player>::default(),
            FightPlayer,
            FightScene,
        ))
        .observe(crate::systems::character_controller::setup_idle_animation);

    // Spawn the enemy model with AI and animations
    commands
        .spawn((
            Name::new("Fight Enemy"),
            GltfSceneRoot::new(assets.enemy.clone()),
            Transform {
                translation: Vec3::new(5.0, -1.65, 0.0),
                rotation: Quat::from_rotation_y(std::f32::consts::PI),
                scale: Vec3::splat(4.0),
                ..default()
            },
            EnemyBundle::default(),
            Friction::new(0.5),
            Restitution::new(0.0),
            GravityScale(1.0),
            CollisionEventsEnabled, // Enable collision events
            FightEnemy,
            FightScene,
        ))
        .observe(crate::systems::character_controller::setup_idle_animation);

    // Add a camera (match gameplay)
    commands.spawn((
        Name::new("Fight Camera"),
        Camera3d::default(),
        Camera {
            order: 1,
            ..default()
        },
        Transform::from_xyz(0.0, 4.0, -12.0).looking_at(Vec3::new(0.0, 2.0, 0.0), Vec3::Y),
        FightScene,
    ));

    // Add a simple UI text to show we're in the fight scene
    commands
        .spawn((
            Node {
                width: Val::Percent(100.0),
                height: Val::Percent(100.0),
                justify_content: JustifyContent::Center,
                align_items: AlignItems::Center,
                ..default()
            },
            FightScene,
        ))
        .with_children(|parent| {
            // Health bars row
            // Use player_hud_widget for both player and enemy
            parent.spawn(crate::ui::widgets::player_hud_widget(
                ui_assets.player_avatar.clone(),
                "Player",
                2,         // example level
                (80, 100), // example health
                (50, 100), // example xp
                font_assets.rajdhani_bold.clone(),
                crate::ui::widgets::HudPosition::Left,
            ));
            parent.spawn(crate::ui::widgets::player_hud_widget(
                ui_assets.enemy_avatar.clone(),
                "Enemy",
                3,          // example level
                (120, 150), // example health
                (90, 100),  // example xp
                font_assets.rajdhani_medium.clone(),
                crate::ui::widgets::HudPosition::Right,
            ));
            parent.spawn((
                Text::new("FIGHT SCENE\nPress ESC to return to gameplay\nPress COMMA from gameplay to enter fight"),
                TextFont {
                    font_size: 40.0,
                    ..default()
                },
                TextColor::WHITE,
                FightScene,
            ));
        });
}

fn handle_fight_input(
    keyboard_input: Res<ButtonInput<KeyCode>>,
    mut next_state: ResMut<NextState<Screen>>,
) {
    // Return to gameplay when ESC is pressed
    if keyboard_input.just_pressed(KeyCode::Escape) {
        next_state.set(Screen::GamePlay);
    }
}

fn camera_follow_fight_player(
    player_query: Query<
        &Transform,
        (
            With<crate::systems::character_controller::CharacterController>,
            With<FightScene>,
        ),
    >,
    mut camera_query: Query<
        &mut Transform,
        (
            With<Camera3d>,
            With<FightScene>,
            Without<crate::systems::character_controller::CharacterController>,
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

fn despawn_collectibles(
    mut commands: Commands,
    query: Query<Entity, With<crate::systems::collectibles::Collectible>>,
) {
    for entity in &query {
        commands.entity(entity).despawn();
    }
}

// ===== SCENE MARKER =====

#[derive(Component, Default, Clone)]
struct FightScene;

// ===== TURN-BASED COMBAT SYSTEM =====

/// Represents who's turn it is in combat
#[derive(Resource, Default, Debug, Clone, PartialEq)]
pub enum CombatTurn {
    #[default]
    Enemy,
    Player,
    OutOfRange,
}

/// Combat state resource that tracks the current turn and state
#[derive(Resource, Default)]
pub struct CombatState {
    pub current_turn: CombatTurn,
    pub enemy_attack_done: bool,
    pub player_waiting_for_input: bool,
    pub in_range: bool,
    pub enemy_attack_finished: bool, // Track if enemy attack animation has finished
    pub player_attack_finished: bool, // Track if player attack animation has finished
    pub player_turn_start_time: f32, // Track when player turn started
}

/// Timer for enemy attack duration
#[derive(Resource, Default)]
pub struct TurnTimer {
    pub timer: Timer,
}

impl TurnTimer {
    pub fn new(duration: f32) -> Self {
        Self {
            timer: Timer::from_seconds(duration, TimerMode::Once),
        }
    }
}

/// Marker component for player in fight scene
#[derive(Component)]
pub struct FightPlayer;

/// Marker component for enemy in fight scene
#[derive(Component)]
pub struct FightEnemy;

/// Initialize combat state when entering fight scene
fn initialize_combat(mut combat_state: ResMut<CombatState>, mut turn_timer: ResMut<TurnTimer>) {
    combat_state.current_turn = CombatTurn::Enemy;
    combat_state.enemy_attack_done = false;
    combat_state.player_waiting_for_input = false;
    combat_state.in_range = false;
    combat_state.enemy_attack_finished = false;
    combat_state.player_attack_finished = false;
    combat_state.player_turn_start_time = 0.0;
    *turn_timer = TurnTimer::new(2.0); // 2 second enemy attack duration
}

/// Reset combat state when exiting fight scene
fn reset_combat(mut combat_state: ResMut<CombatState>, mut turn_timer: ResMut<TurnTimer>) {
    *combat_state = CombatState::default();
    *turn_timer = TurnTimer::default();
}

/// Main turn-based combat management system
fn manage_turn_based_combat(
    _time: Res<Time>,
    mut combat_state: ResMut<CombatState>,
    mut turn_timer: ResMut<TurnTimer>,
    player_query: Query<&Transform, (With<FightPlayer>, Without<FightEnemy>)>,
    enemy_query: Query<&Transform, (With<FightEnemy>, Without<FightPlayer>)>,
    _enemy_animation_query: Query<
        &mut crate::systems::character_controller::AnimationState,
        (With<FightEnemy>, Without<FightPlayer>),
    >,
) {
    // Check if players are in range
    if let (Ok(player_transform), Ok(enemy_transform)) =
        (player_query.single(), enemy_query.single())
    {
        let distance = player_transform
            .translation
            .distance(enemy_transform.translation);
        let attack_range = 3.0; // Same as EnemyAI attack_range

        let players_in_range = distance <= attack_range;
        let was_in_range = combat_state.in_range;
        combat_state.in_range = players_in_range;

        if !players_in_range {
            // When out of range, switch to OutOfRange mode (existing behavior)
            if combat_state.current_turn != CombatTurn::OutOfRange {
                combat_state.current_turn = CombatTurn::OutOfRange;
                combat_state.enemy_attack_done = false;
                combat_state.player_waiting_for_input = false;
                turn_timer.timer.reset();
            }
            return;
        }

        // Just entered range - start with enemy turn
        if !was_in_range && players_in_range {
            combat_state.current_turn = CombatTurn::Enemy;
            combat_state.enemy_attack_done = false;
            combat_state.player_waiting_for_input = false;
            turn_timer.timer = Timer::from_seconds(2.0, TimerMode::Once);
            turn_timer.timer.reset(); // Start timer immediately
        }

        // Handle turn transitions when in range
        match combat_state.current_turn {
            CombatTurn::Enemy => {
                // Enemy turn: wait for enemy attack animation to finish
                if combat_state.enemy_attack_finished {
                    // Switch to player turn when enemy attack is done
                    combat_state.current_turn = CombatTurn::Player;
                    combat_state.enemy_attack_done = true;
                    combat_state.player_waiting_for_input = true;
                    combat_state.enemy_attack_finished = false; // Reset for next turn
                    combat_state.player_turn_start_time = 0.0; // Will be set by time system
                }
            }
            CombatTurn::Player => {
                // Player turn: wait for player attack animation to finish
                if combat_state.player_attack_finished {
                    // Switch back to enemy turn when player attack is done
                    combat_state.current_turn = CombatTurn::Enemy;
                    combat_state.enemy_attack_done = false;
                    combat_state.player_waiting_for_input = false;
                    combat_state.player_attack_finished = false; // Reset for next turn
                    println!("🎯 TURN SWITCH: Player → Enemy (player attack finished)");
                }
            }
            _ => {}
        }
    }
}

/// Handle enemy turn behavior
fn handle_enemy_turn(
    combat_state: ResMut<CombatState>,
    mut enemy_query: Query<
        (
            &mut crate::systems::character_controller::AnimationState,
            &mut crate::systems::enemy_ai::EnemyAI,
        ),
        (With<FightEnemy>, Without<FightPlayer>),
    >,
) {
    if let Ok((_animation_state, mut enemy_ai)) = enemy_query.single_mut() {
        match combat_state.current_turn {
            CombatTurn::Enemy if combat_state.in_range => {
                // Force enemy to stay in place during enemy turn
                enemy_ai.is_moving = false;
            }
            CombatTurn::Player if combat_state.in_range => {
                // During player turn, enemy should be idle
                enemy_ai.is_moving = false;
            }
            CombatTurn::OutOfRange => {
                // Let normal enemy AI take over (existing behavior)
            }
            _ => {}
        }
    }
}

/// Handle player turn behavior
fn handle_player_turn(
    combat_state: ResMut<CombatState>,
    _turn_timer: ResMut<TurnTimer>,
    player_query: Query<
        &crate::systems::character_controller::AnimationState,
        (With<FightPlayer>, Without<FightEnemy>),
    >,
) {
    if let Ok(player_animation_state) = player_query.single() {
        match combat_state.current_turn {
            CombatTurn::Player if combat_state.in_range => {
                // Player turn is handled by the event-driven system in manage_turn_based_combat
                // This system just monitors player state but doesn't control turn switching
                if player_animation_state.fight_move_1 || player_animation_state.fight_move_2 {
                    // Player is currently attacking, wait for animation to finish
                    // The event-driven system will handle turn switching when animation finishes
                }
                // If player_waiting_for_input is true, we're waiting for player to press X
            }
            _ => {}
        }
    }
}

/// Detect when player starts attacking and update combat state
fn detect_player_attack(
    mut combat_state: ResMut<CombatState>,
    player_query: Query<
        &crate::systems::character_controller::AnimationState,
        (With<FightPlayer>, Without<FightEnemy>),
    >,
) {
    if let Ok(player_animation_state) = player_query.single() {
        // If player just started attacking during their turn
        if combat_state.current_turn == CombatTurn::Player
            && combat_state.in_range
            && combat_state.player_waiting_for_input
            && (player_animation_state.fight_move_1 || player_animation_state.fight_move_2)
        {
            // Player is no longer waiting for input - they've started attacking
            combat_state.player_waiting_for_input = false;
            println!("🎮 PLAYER: Started attack animation");
        }
    }
}

/// Detects when enemy attack animations finish and updates combat state
fn detect_enemy_attack_finished(
    mut combat_state: ResMut<CombatState>,
    enemy_query: Query<
        (
            &crate::systems::character_controller::AnimationState,
            &GltfAnimations,
        ),
        (With<FightEnemy>, Without<FightPlayer>),
    >,
    animation_players: Query<&AnimationPlayer>,
) {
    for (animation_state, animations) in &enemy_query {
        // Check if enemy attack animation has finished
        if animation_state.current_animation == animations::enemy::ATTACK {
            if let Ok(player) = animation_players.get(animations.animation_player) {
                if player.all_finished() {
                    combat_state.enemy_attack_finished = true;
                    println!("✅ ENEMY: Attack animation finished");
                }
            }
        }
    }
}

/// Tracks player turn time and ensures player has enough time to attack
fn track_player_turn_time(time: Res<Time>, mut combat_state: ResMut<CombatState>) {
    if combat_state.current_turn == CombatTurn::Player && combat_state.player_waiting_for_input {
        // We used to auto-switch back to enemy after 5 seconds.
        // Disabled: keep player turn active indefinitely until the player actually attacks.
        // Leave bookkeeping in case we want telemetry later.
        if combat_state.player_turn_start_time == 0.0 {
            combat_state.player_turn_start_time = time.elapsed_secs();
        }
        // No timeout transition.
    }
}
