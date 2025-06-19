use bevy::prelude::*;
use crate::screens::Screen;

pub(super) fn plugin(app: &mut App) {
    app.add_systems(OnEnter(Screen::GamePlay), create_game_system);
}

/// System to initialize game state when entering gameplay
fn create_game_system() {
    info!("Game state initialized for new gameplay session");
    // TODO: Implement game state initialization logic
    // This could include:
    // - Creating player entity on blockchain
    // - Setting up initial game parameters
    // - Synchronizing client state with blockchain
}
