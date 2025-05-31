use bevy::prelude::*;
use bevy::window::{MonitorSelection, WindowMode};
use bevy_enhanced_input::prelude::*;

pub fn plugin(app: &mut App) {
    app.add_systems(Startup, spawn)
        .add_plugins(EnhancedInputPlugin)
        .add_input_context::<Player>()
        .add_input_context::<SystemInput>()
        .add_observer(handle_toggle_fullscreen)
        .add_observer(player_binding)
        .add_observer(global_binding)
        .add_observer(apply_movement)
        .add_observer(jump);
}

fn spawn(mut commands: Commands) {
    commands.spawn(Actions::<SystemInput>::default());
}

fn player_binding(trigger: Trigger<Binding<Player>>, mut players: Query<&mut Actions<Player>>) {
    let mut actions = players.get_mut(trigger.target()).unwrap();
    // Movement (WASD, Arrow Keys, Gamepad Left Stick)
    actions.bind::<Move>().to((
        Cardinal::wasd_keys(),
        Axial::left_stick(),
        Cardinal::arrow_keys(),
    ));
    // Jump (Spacebar)
    actions
        .bind::<Jump>()
        .to((KeyCode::Space, GamepadButton::South));
}

fn global_binding(
    trigger: Trigger<Binding<SystemInput>>,
    mut systems: Query<&mut Actions<SystemInput>>,
) {
    let mut actions = systems.get_mut(trigger.target()).unwrap();
    // Toggle Fullscreen (F11)
    actions
        .bind::<ToggleFullScreen>()
        .to((KeyCode::F11, (KeyCode::AltLeft, KeyCode::Enter)));
}

fn apply_movement(trigger: Trigger<Fired<Move>>) {
    info!("moving: {}", trigger.value);
}

fn jump(_trigger: Trigger<Started<Jump>>) {
    info!("jumping");
}

#[derive(InputContext)]
struct Player;

#[derive(Debug, InputAction)]
#[input_action(output = Vec2)]
struct Move;

#[derive(Debug, InputAction)]
#[input_action(output = bool)]
struct Jump;

/// Input context for the Elysium game
#[derive(InputContext)]
pub struct SystemInput;

/// Action for toggling between fullscreen and windowed mode
#[derive(Debug, InputAction)]
#[input_action(output = bool)]
struct ToggleFullScreen;

fn handle_toggle_fullscreen(
    trigger: Trigger<Started<ToggleFullScreen>>,
    mut windows: Query<&mut Window>,
) {
    if trigger.value {
        if let Ok(mut window) = windows.single_mut() {
            window.mode = match window.mode {
                WindowMode::Windowed => {
                    info!("Switching to fullscreen");
                    WindowMode::BorderlessFullscreen(MonitorSelection::Primary)
                }
                _ => {
                    info!("Switching to windowed");
                    WindowMode::Windowed
                }
            };
        } else {
            error!("Failed to get window");
        }
    }
}
