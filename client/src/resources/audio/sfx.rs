// Sound Effects
use bevy::prelude::*;
use bevy_kira_audio::prelude::*;

use crate::assets::AudioAssets;
use crate::resources::audio::{SfxChannel, AudioSettings};

#[derive(Event)]
pub struct PlaySfxEvent {
    pub sfx_type: SfxType,
}

#[derive(Clone, Copy, Debug)]
pub enum SfxType {
    CoinCollect,
}

pub struct SfxPlugin;

impl Plugin for SfxPlugin {
    fn build(&self, app: &mut App) {
        app.add_event::<PlaySfxEvent>()
            .add_systems(Update, play_sfx_events);
    }
}

fn play_sfx_events(
    mut sfx_events: EventReader<PlaySfxEvent>,
    audio_assets: Option<Res<AudioAssets>>,
    sfx_channel: Res<AudioChannel<SfxChannel>>,
    audio_settings: Res<AudioSettings>,
) {
    let Some(assets) = audio_assets else {
        return;
    };

    for event in sfx_events.read() {
        if audio_settings.muted {
            continue;
        }

        match event.sfx_type {
            SfxType::CoinCollect => {
                sfx_channel.play(assets.coin_sound.clone());
            }
        }
    }
}
