use crate::constants::{KATANA_URL, TORII_URL, WORLD_ADDRESS};
use bevy::prelude::*;
use dojo_bevy_plugin::{DojoResource, TokioRuntime};

pub fn plugin(app: &mut App) {
    app.add_systems(Startup, handle_dojo_setup);
}

fn handle_dojo_setup(tokio: Res<TokioRuntime>, mut dojo: ResMut<DojoResource>) {
    dojo.connect_torii(&tokio, TORII_URL.to_string(), WORLD_ADDRESS);
    dojo.connect_predeployed_account(&tokio, KATANA_URL.to_string(), 0);
}
