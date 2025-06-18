use starknet::core::types::Felt;
use starknet::macros::selector;

pub const TORII_URL: &str = "http://localhost:8080";
pub const KATANA_URL: &str = "http://0.0.0.0:5050";

// Needs to be found from manifest.
pub const WORLD_ADDRESS: Felt =
    Felt::from_hex_unchecked("0x04d9778a74d2c9e6e7e4a24cbe913998a80de217c66ee173a604d06dea5469c3");
pub const ACTION_ADDRESS: Felt =
    Felt::from_hex_unchecked("0x00b056c9813fdc442118bdfead6fda526e5daa5fd7d543304117ed80154ea752");
pub const SPAWN_SELECTOR: Felt = selector!("spawn");
pub const MOVE_SELECTOR: Felt = selector!("move");
