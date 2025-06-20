use bevy::prelude::*;
use dojo_bevy_plugin::{DojoResource, TokioRuntime};
use starknet::core::types::Call;
use crate::constants::dojo::CREATE_GAME_SELECTOR;
use crate::screens::Screen;

/// Event to trigger game creation on the blockchain
#[derive(Event, Debug)]
pub struct CreateGameEvent;

/// Event emitted when a game is successfully created
#[derive(Event, Debug)]
pub struct GameCreatedEvent {
    pub game_id: u32,
    pub player_address: String,
}

/// Event emitted when game creation fails
#[derive(Event, Debug)]
pub struct GameCreationFailedEvent {
    pub error: String,
}

/// Resource to track the current game state
#[derive(Resource, Debug, Default)]
pub struct GameState {
    pub current_game_id: Option<u32>,
    pub is_creating_game: bool,
    pub player_address: Option<String>,
}

pub(super) fn plugin(app: &mut App) {
    app.add_event::<CreateGameEvent>()
        .add_event::<GameCreatedEvent>()
        .add_event::<GameCreationFailedEvent>()
        .init_resource::<GameState>()
        .add_systems(OnEnter(Screen::GamePlay), auto_create_game_system)
        .add_systems(Update, (
            handle_create_game_events,
            handle_game_created_events,
            handle_game_creation_failed_events,
        ).run_if(in_state(Screen::GamePlay)));
}

/// System to automatically create a game when entering gameplay (if not already created)
fn auto_create_game_system(
    mut create_game_events: EventWriter<CreateGameEvent>,
    game_state: Res<GameState>,
) {
    if game_state.current_game_id.is_none() && !game_state.is_creating_game {
        info!("Auto-creating game for new gameplay session");
        create_game_events.write(CreateGameEvent);
    }
}

/// System to handle CreateGameEvent and call the blockchain
fn handle_create_game_events(
    mut events: EventReader<CreateGameEvent>,
    mut dojo: ResMut<DojoResource>,
    tokio: Res<TokioRuntime>,
    dojo_config: Res<super::DojoSystemState>,
    mut game_state: ResMut<GameState>,
) {
    for _event in events.read() {
        if game_state.is_creating_game {
            warn!("Game creation already in progress, ignoring duplicate request");
            continue;
        }

        if game_state.current_game_id.is_some() {
            warn!("Game already exists with ID {:?}", game_state.current_game_id);
            continue;
        }

        info!("Creating new game on blockchain...");
        game_state.is_creating_game = true;

        // Create the contract call for create_game function
        let call = Call {
            to: dojo_config.config.action_address,
            selector: CREATE_GAME_SELECTOR,
            calldata: vec![], // create_game takes no parameters
        };

        // Queue the call to the blockchain
        dojo.queue_tx(&tokio, vec![call]);
        info!("Game creation call queued successfully");
        
        // Note: The actual response will be handled when the transaction is processed
        // For now, we'll simulate success after a delay in a real implementation
        // you'd listen for blockchain events or poll for transaction status
    }
}

/// System to handle successful game creation
fn handle_game_created_events(
    mut events: EventReader<GameCreatedEvent>,
    mut game_state: ResMut<GameState>,
) {
    for event in events.read() {
        info!("Game created successfully! Game ID: {}, Player: {}", 
              event.game_id, event.player_address);
        
        game_state.current_game_id = Some(event.game_id);
        game_state.player_address = Some(event.player_address.clone());
        game_state.is_creating_game = false;
        
        // TODO: You could trigger UI updates here, or initialize level 1
        info!("Game state updated - ready to start playing!");
    }
}

/// System to handle failed game creation
fn handle_game_creation_failed_events(
    mut events: EventReader<GameCreationFailedEvent>,
    mut game_state: ResMut<GameState>,
) {
    for event in events.read() {
        error!("Game creation failed: {}", event.error);
        game_state.is_creating_game = false;
        
        // TODO: Show error message to user
        // TODO: Optionally retry after a delay
    }
}
