use crate::systems::character_controller::AnimationState;
use avian3d::{math::*, prelude::*};
use bevy::prelude::*;
use bevy_gltf_animation::prelude::*;

/// Marker component for enemy entities
#[derive(Component)]
pub struct Enemy;

/// Component to track enemy AI state
#[derive(Component)]
pub struct EnemyAI {
    pub attack_range: f32,
    pub move_speed: f32,
    pub is_moving: bool,
}

impl Default for EnemyAI {
    fn default() -> Self {
        Self {
            attack_range: 3.0,
            move_speed: 3.0,
            is_moving: false,
        }
    }
}

/// Bundle for enemy entities
#[derive(Bundle)]
pub struct EnemyBundle {
    pub enemy: Enemy,
    pub ai: EnemyAI,
    pub animation_state: AnimationState,
    pub body: RigidBody,
    pub collider: Collider,
    pub locked_axes: LockedAxes,
    pub ground_caster: ShapeCaster,
}

impl Default for EnemyBundle {
    fn default() -> Self {
        Self {
            enemy: Enemy,
            ai: EnemyAI::default(),
            animation_state: AnimationState {
                forward_hold_time: 0.0,
                current_animation: 0, // Start uninitialized to prevent twitching
                fight_move_1: false,
                fight_move_2: false,
            },
            body: RigidBody::Kinematic, // Use kinematic instead of dynamic
            collider: Collider::capsule(0.5, 1.5),
            locked_axes: LockedAxes::ROTATION_LOCKED,
            ground_caster: ShapeCaster::new(
                Collider::sphere(0.2),
                Vector::ZERO,
                Quaternion::default(),
                Dir3::NEG_Y,
            )
            .with_max_distance(2.0), // Ground detection
        }
    }
}

/// Plugin for enemy AI systems
pub struct EnemyAIPlugin;

impl Plugin for EnemyAIPlugin {
    fn build(&self, app: &mut App) {
        app.add_systems(Update, (enemy_ai_movement, enemy_ai_animations));
    }
}

/// System that handles enemy movement towards the player
fn enemy_ai_movement(
    time: Res<Time>,
    mut enemy_query: Query<
        (
            &mut Transform,
            &mut LinearVelocity,
            &mut EnemyAI,
            &mut AnimationState,
        ),
        (
            With<Enemy>,
            Without<crate::systems::character_controller::CharacterController>,
        ),
    >,
    player_query: Query<
        &Transform,
        (
            With<crate::systems::character_controller::CharacterController>,
            Without<Enemy>,
        ),
    >,
    combat_state: Option<Res<crate::screens::fight::CombatState>>,
) {
    let delta_time = time.delta_secs();

    // Find the player
    let Ok(player_transform) = player_query.single() else {
        return;
    };

    for (mut enemy_transform, mut enemy_velocity, mut enemy_ai, mut animation_state) in
        &mut enemy_query
    {
        let player_pos = player_transform.translation;
        let enemy_pos = enemy_transform.translation;
        let distance_to_player = enemy_pos.distance(player_pos);

        // Check if we're in a turn-based combat scenario
        let in_turn_based_combat = if let Some(combat_state) = &combat_state {
            combat_state.in_range
                && (combat_state.current_turn == crate::screens::fight::CombatTurn::Enemy
                    || combat_state.current_turn == crate::screens::fight::CombatTurn::Player)
        } else {
            false
        };

        if in_turn_based_combat {
            // In turn-based combat, movement is controlled by the fight scene
            enemy_velocity.x = 0.0;
            enemy_velocity.z = 0.0;
            enemy_velocity.y = 0.0;
            animation_state.forward_hold_time = 0.0;

            // Face the player
            let direction_to_player = (player_pos - enemy_pos).normalize();
            let direction_2d = Vec2::new(direction_to_player.x, direction_to_player.z).normalize();
            let target_rotation =
                Quat::from_rotation_arc(Vec3::Z, Vec3::new(direction_2d.x, 0.0, direction_2d.y));
            enemy_transform.rotation = enemy_transform
                .rotation
                .slerp(target_rotation, 3.0 * delta_time);

            // Keep on ground
            enemy_transform.translation.y = -1.65;
        } else {
            // Normal AI behavior when not in turn-based combat or out of range
            if distance_to_player > enemy_ai.attack_range {
                // Set moving state
                enemy_ai.is_moving = true;

                // Move towards player
                let direction_to_player = (player_pos - enemy_pos).normalize();
                let target_velocity = direction_to_player * enemy_ai.move_speed;

                // Apply movement
                enemy_velocity.x = enemy_velocity.x.lerp(target_velocity.x, 5.0 * delta_time);
                enemy_velocity.z = enemy_velocity.z.lerp(target_velocity.z, 5.0 * delta_time);
                enemy_velocity.y = 0.0;

                // Rotate to face player
                let direction_2d =
                    Vec2::new(direction_to_player.x, direction_to_player.z).normalize();
                let target_rotation = Quat::from_rotation_arc(
                    Vec3::Z,
                    Vec3::new(direction_2d.x, 0.0, direction_2d.y),
                );
                enemy_transform.rotation = enemy_transform
                    .rotation
                    .slerp(target_rotation, 3.0 * delta_time);

                // Keep on ground
                enemy_transform.translation.y = -1.65;

                // Update animation state
                let horizontal_speed = Vec2::new(enemy_velocity.x, enemy_velocity.z).length();
                if horizontal_speed > 0.1 {
                    animation_state.forward_hold_time += delta_time;
                } else {
                    animation_state.forward_hold_time = 0.0;
                }
            } else {
                // Set idle state
                enemy_ai.is_moving = false;

                // Stop moving when close to player - stop immediately
                enemy_velocity.x = 0.0;
                enemy_velocity.z = 0.0;
                enemy_velocity.y = 0.0;
                animation_state.forward_hold_time = 0.0;
            }
        }
    }
}

/// Updates enemy animations based on AI state
fn enemy_ai_animations(
    mut query: Query<
        (&mut GltfAnimations, &mut AnimationState),
        (
            With<Enemy>,
            Without<crate::systems::character_controller::CharacterController>,
        ),
    >,
    mut animation_players: Query<&mut AnimationPlayer>,
    combat_state: Option<Res<crate::screens::fight::CombatState>>,
) {
    for (mut animations, mut animation_state) in &mut query {
        let prev = animation_state.current_animation;
        // When CombatState exists, we are in the fight scene and must follow strict turn-based rules
        let in_turn_based_combat = combat_state.is_some();

        if in_turn_based_combat {
            // In turn-based combat - check whose turn it is
            if let Some(combat_state) = &combat_state {
                match combat_state.current_turn {
                    crate::screens::fight::CombatTurn::Enemy => {
                        // If this turn's attack already finished, keep enemy idle until turn switches
                        if combat_state.enemy_attack_finished {
                            if let Some(animation) = animations.get_by_number(2) {
                                if let Ok(mut player) =
                                    animation_players.get_mut(animations.animation_player)
                                {
                                    player.stop_all();
                                    player.play(animation).repeat();
                                    animation_state.current_animation = 2;
                                }
                            }
                            if prev != animation_state.current_animation {
                                println!(
                                    "👹 ENEMY ANIM CHANGE (Enemy turn, finished): {} → {}",
                                    prev, animation_state.current_animation
                                );
                            }
                            animation_state.fight_move_1 = false;
                            animation_state.fight_move_2 = false;
                            continue;
                        }

                        // ENEMY TURN and not finished: ensure attack (index 4) is playing
                        if animation_state.current_animation != 4 {
                            if let Some(animation) = animations.get_by_number(4) {
                                if let Ok(mut player) =
                                    animation_players.get_mut(animations.animation_player)
                                {
                                    player.stop_all();
                                    player.play(animation);
                                    animation_state.current_animation = 4;
                                    animation_state.fight_move_1 = true; // Mark as attacking
                                }
                            }
                            if prev != animation_state.current_animation {
                                println!(
                                    "👹 ENEMY ANIM CHANGE (Enemy turn, attack): {} → {}",
                                    prev, animation_state.current_animation
                                );
                            }
                        }
                        // Do not force-switch to idle here; wait for detect system to flag finished
                    }
                    crate::screens::fight::CombatTurn::Player => {
                        // PLAYER TURN: Enemy must be IDLE (index 2) indefinitely until player attacks
                        let target_animation = 2; // Idle animation
                        // If somehow still on attack, log and correct
                        if animation_state.current_animation == 4 {
                            println!(
                                "🧯 FIX: Enemy was attacking during Player turn → forcing idle"
                            );
                        }
                        // Enforce idle only if changing to reduce spam
                        if animation_state.current_animation != target_animation {
                            if let Some(animation) = animations.get_by_number(target_animation) {
                                if let Ok(mut player) =
                                    animation_players.get_mut(animations.animation_player)
                                {
                                    player.stop_all();
                                    player.play(animation).repeat();
                                    animation_state.current_animation = target_animation;
                                }
                            }
                            println!(
                                "👹 ENEMY ANIM CHANGE (Player turn, idle): {} → {}",
                                prev, animation_state.current_animation
                            );
                        }
                        // Clear any attack flags during player turn
                        animation_state.fight_move_1 = false;
                        animation_state.fight_move_2 = false;
                    }
                    _ => {
                        // Default to idle for any other state
                        let target_animation = 2; // Idle animation
                        if target_animation != animation_state.current_animation {
                            if let Some(animation) = animations.get_by_number(target_animation) {
                                if let Ok(mut player) =
                                    animation_players.get_mut(animations.animation_player)
                                {
                                    player.stop_all();
                                    player.play(animation).repeat();
                                    animation_state.current_animation = target_animation;
                                }
                            }
                            println!(
                                "👹 ENEMY ANIM CHANGE (Other, idle): {} → {}",
                                prev, animation_state.current_animation
                            );
                        }
                    }
                }
            }
        } else {
            // Normal movement animations - enemy follows player
            let target_animation = if animation_state.forward_hold_time >= 3.0 {
                4 // Running animation
            } else if animation_state.forward_hold_time > 0.0 {
                7 // Walking animation
            } else {
                2 // Idle animation
            };

            if target_animation != animation_state.current_animation {
                if let Some(animation) = animations.get_by_number(target_animation) {
                    if let Ok(mut player) = animation_players.get_mut(animations.animation_player) {
                        player.stop_all();
                        if target_animation == 2 {
                            player.play(animation).repeat();
                        } else {
                            player.play(animation);
                        }
                        animation_state.current_animation = target_animation;
                    }
                }
                println!(
                    "👹 ENEMY ANIM CHANGE (Chase): {} → {}",
                    prev, animation_state.current_animation
                );
            }
        }
    }
}
