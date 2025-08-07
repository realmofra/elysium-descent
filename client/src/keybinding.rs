use bevy::prelude::*;
use bevy::window::{MonitorSelection, WindowMode};
use bevy_enhanced_input::prelude::*;

use crate::screens::Screen;

pub fn plugin(app: &mut App) {
    app.add_systems(Startup, spawn_system_action)
        .add_plugins(EnhancedInputPlugin)
        .add_input_context::<Player>()
        .add_input_context::<SystemInput>()
        .add_input_context::<DojoInput>()
        .add_observer(handle_toggle_fullscreen)
        .add_observer(handle_return_to_menu)
        .add_observer(player_binding)
        .add_observer(global_binding)
        .add_observer(dojo_binding)
        .add_observer(apply_movement)
        .add_observer(jump)
        .add_observer(sprint_started)
        .add_observer(sprint_completed)
        .add_observer(handle_create_game)
        .add_observer(handle_interact)
        .add_observer(handle_fight_move)
        .add_observer(handle_go_to_fight_scene)
        .add_systems(Update, test_key_press);
}

fn spawn_system_action(mut commands: Commands) {
    commands.spawn(Actions::<SystemInput>::default());
    commands.spawn(Actions::<DojoInput>::default());
}

fn player_binding(trigger: Trigger<Binding<Player>>, mut players: Query<&mut Actions<Player>>) {
    if let Ok(mut actions) = players.get_mut(trigger.target()) {
        // Movement (WASD, Arrow Keys, Gamepad Left Stick)
        actions
            .bind::<Move>()
            .to((
                Cardinal::wasd_keys(),
                Axial::left_stick(),
                Cardinal::arrow_keys(),
            ))
            .with_modifiers(DeadZone::default());
        // Jump (Spacebar)
        actions
            .bind::<Jump>()
            .to((KeyCode::Space, GamepadButton::South));

        // Sprint (Shift keys)
        actions
            .bind::<Sprint>()
            .to((KeyCode::ShiftLeft, KeyCode::ShiftRight));

        // Interact (E key)
        actions.bind::<Interact>().to(KeyCode::KeyE);

        // Fight Move: allow X or Shift+X (either left or right shift)
        actions
            .bind::<FightMove>()
            .to((
                KeyCode::KeyX,
                (KeyCode::ShiftLeft, KeyCode::KeyX),
                (KeyCode::ShiftRight, KeyCode::KeyX),
            ));

        // Go to Fight Scene (Comma key)
        actions.bind::<GoToFightScene>().to(KeyCode::Comma);
    } else {
        error!(
            "Failed to get player actions for entity {:?}",
            trigger.target()
        );
    }
}

fn global_binding(
    trigger: Trigger<Binding<SystemInput>>,
    mut systems: Query<&mut Actions<SystemInput>>,
) {
    if let Ok(mut actions) = systems.get_mut(trigger.target()) {
        // Toggle Fullscreen (F11)
        actions
            .bind::<ToggleFullScreen>()
            .to((KeyCode::F11, (KeyCode::AltLeft, KeyCode::Enter)));

        actions.bind::<ReturnToMainMenu>().to(KeyCode::Escape);
    } else {
        error!(
            "Failed to get system actions for entity {:?}",
            trigger.target()
        );
    }
}

fn dojo_binding(
    trigger: Trigger<Binding<DojoInput>>,
    mut dojo_actions: Query<&mut Actions<DojoInput>>,
) {
    if let Ok(mut actions) = dojo_actions.get_mut(trigger.target()) {
        // Create Game (G key)
        actions.bind::<CreateGame>().to(KeyCode::KeyG);
    } else {
        error!(
            "Failed to get dojo actions for entity {:?}",
            trigger.target()
        );
    }
}

// Forward movement and jump events to the character controller
fn apply_movement(
    trigger: Trigger<Fired<Move>>,
    mut movement_events: EventWriter<crate::systems::character_controller::MovementAction>,
    mut last_input: ResMut<crate::systems::character_controller::LastInputDirection>,
) {
    let direction = trigger.value;
    if direction != Vec2::ZERO {
        // Convert Vec2 to avian3d Vector2
        let avian_direction = avian3d::math::Vector2::new(direction.x, direction.y);
        movement_events.write(crate::systems::character_controller::MovementAction::Move(
            avian_direction,
        ));
        last_input.0 = direction;
    }
}

fn jump(
    _trigger: Trigger<Started<Jump>>,
    mut movement_events: EventWriter<crate::systems::character_controller::MovementAction>,
) {
    movement_events.write(crate::systems::character_controller::MovementAction::Jump);
}

fn sprint_started(
    _trigger: Trigger<Started<Sprint>>,
    mut animation_query: Query<&mut crate::systems::character_controller::AnimationState>,
) {
    if let Ok(mut animation_state) = animation_query.single_mut() {
        // Set sprint animation
        animation_state.forward_hold_time = 4.0;
    }
}

fn sprint_completed(
    _trigger: Trigger<Completed<Sprint>>,
    mut animation_query: Query<&mut crate::systems::character_controller::AnimationState>,
) {
    if let Ok(mut animation_state) = animation_query.single_mut() {
        // Reset to normal movement
        animation_state.forward_hold_time = 0.0;
    }
}

#[derive(InputContext)]
pub struct Player;

#[derive(Debug, InputAction)]
#[input_action(output = Vec2)]
pub struct Move;

#[derive(Debug, InputAction)]
#[input_action(output = bool)]
pub struct Jump;

#[derive(Debug, InputAction)]
#[input_action(output = bool)]
pub struct Sprint;

#[derive(Debug, InputAction)]
#[input_action(output = bool)]
pub struct Interact;

#[derive(Debug, InputAction)]
#[input_action(output = bool)]
pub struct FightMove;

#[derive(Debug, InputAction)]
#[input_action(output = bool)]
pub struct GoToFightScene;

/// Input context for the Elysium game
#[derive(InputContext)]
pub struct SystemInput;

/// Action for toggling between fullscreen and windowed mode
#[derive(Debug, InputAction)]
#[input_action(output = bool)]
struct ToggleFullScreen;

/// Action for returning to the main menu
#[derive(Debug, InputAction)]
#[input_action(output = bool)]
struct ReturnToMainMenu;

/// Input context for Dojo blockchain interactions
#[derive(InputContext)]
pub struct DojoInput;

/// Action for creating a new game on the blockchain
#[derive(Debug, InputAction)]
#[input_action(output = bool)]
struct CreateGame;

fn handle_toggle_fullscreen(
    trigger: Trigger<Started<ToggleFullScreen>>,
    mut windows: Query<&mut Window>,
) {
    if trigger.value {
        if let Ok(mut window) = windows.single_mut() {
            window.mode = match window.mode {
                WindowMode::Windowed => WindowMode::BorderlessFullscreen(MonitorSelection::Primary),
                _ => WindowMode::Windowed,
            };
        } else {
            error!("Failed to get window");
        }
    }
}

fn handle_return_to_menu(
    trigger: Trigger<Started<ReturnToMainMenu>>,
    mut next_state: ResMut<NextState<Screen>>,
    modal_state: Option<Res<crate::ui::modal::ModalState>>,
) {
    if trigger.value {
        // Check if modal is open - if so, don't return to main menu
        if let Some(modal_state) = modal_state {
            if modal_state.visible {
                return; // Modal is open, let the modal handle ESC
            }
        }

        next_state.set(Screen::MainMenu);
    }
}

fn handle_create_game(
    trigger: Trigger<Started<CreateGame>>,
    mut create_game_events: EventWriter<crate::systems::dojo::CreateGameEvent>,
) {
    if trigger.value {
        create_game_events.write(crate::systems::dojo::CreateGameEvent);
    }
}

fn handle_interact(
    trigger: Trigger<Started<Interact>>,
    player_query: Query<
        &Transform,
        With<crate::systems::character_controller::CharacterController>,
    >,
    book_query: Query<&Transform, With<crate::systems::book_interaction::Book>>,
    mut next_state: ResMut<NextState<Screen>>,
) {
    if trigger.value {
        // Check if player is near the book
        if let (Ok(player_transform), Ok(book_transform)) =
            (player_query.single(), book_query.single())
        {
            let distance = player_transform
                .translation
                .distance(book_transform.translation);
            let proximity_threshold = 5.0;

            if distance <= proximity_threshold {
                next_state.set(Screen::FightScene);
                return;
            }
        }

        // Note: Coins are now automatically collected by physical contact/collision
    }
}

fn handle_fight_move(
    trigger: Trigger<Started<FightMove>>,
    mut movement_events: EventWriter<crate::systems::character_controller::MovementAction>,
    keyboard: Res<ButtonInput<KeyCode>>,
    combat_state: Option<Res<crate::screens::fight::CombatState>>,
    current_screen: Res<State<Screen>>,
) {
    if trigger.value {
        println!("🔑 FIGHT MOVE: X key pressed!");

        // In fight scene, only allow attacks during player's turn
        if current_screen.get() == &Screen::FightScene {
            println!("🔑 FIGHT MOVE: In fight scene");
            if let Some(combat_state) = combat_state {
                println!(
                    "🔑 FIGHT MOVE: Current turn={:?}, InRange={}",
                    combat_state.current_turn, combat_state.in_range
                );
                // Only allow fight moves during player turn and when in range
                if combat_state.current_turn != crate::screens::fight::CombatTurn::Player
                    || !combat_state.in_range
                {
                    println!("🔑 FIGHT MOVE: BLOCKED - Not player turn or not in range");
                    return; // Block the attack if it's not player's turn
                }
                println!("🔑 FIGHT MOVE: ALLOWED - Player turn and in range");
            } else {
                println!("🔑 FIGHT MOVE: No combat state");
            }
        } else {
            println!("🔑 FIGHT MOVE: Not in fight scene");
        }

        let shift_pressed =
            keyboard.pressed(KeyCode::ShiftLeft) || keyboard.pressed(KeyCode::ShiftRight);
        if shift_pressed {
            println!("🔑 FIGHT MOVE: Sending FightMove2 (Shift+X)");
            movement_events.write(crate::systems::character_controller::MovementAction::FightMove2);
        } else {
            println!("🔑 FIGHT MOVE: Sending FightMove1 (X)");
            movement_events.write(crate::systems::character_controller::MovementAction::FightMove1);
        }
    }
}

// Add a simple test to see if ANY key presses are being detected
fn test_key_press(keyboard: Res<ButtonInput<KeyCode>>, current_screen: Res<State<Screen>>) {
    if current_screen.get() == &Screen::FightScene {
        if keyboard.just_pressed(KeyCode::KeyX) {
            println!("🔑 TEST: X key just pressed!");
        }
        if keyboard.just_pressed(KeyCode::Space) {
            println!("🔑 TEST: Space key just pressed!");
        }
        if keyboard.just_pressed(KeyCode::KeyW) {
            println!("🔑 TEST: W key just pressed!");
        }
    }
}

fn handle_go_to_fight_scene(
    trigger: Trigger<Started<GoToFightScene>>,
    mut next_state: ResMut<NextState<Screen>>,
) {
    if trigger.value {
        next_state.set(Screen::FightScene);
    }
}
