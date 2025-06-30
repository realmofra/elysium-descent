use death_mountain::models::adventurer::adventurer::Adventurer;
use death_mountain::models::adventurer::bag::Bag;
use death_mountain::models::game::GameSettings;
use starknet::ContractAddress;

#[starknet::interface]
pub trait IGameSystems<T> {
    fn start_game(ref self: T, adventurer_id: u64, weapon: u8);
    fn explore(ref self: T, adventurer_id: u64);
    fn attack(ref self: T, adventurer_id: u64, weapon: bool);
    fn flee(ref self: T, adventurer_id: u64);
    fn equip(ref self: T, adventurer_id: u64, item_id: u8);
    fn drop(ref self: T, adventurer_id: u64, item_id: u8);
    fn buy_items(ref self: T, adventurer_id: u64, item_id: u8, equip: bool);
    fn select_stat_upgrades(
        ref self: T,
        adventurer_id: u64,
        strength: u8,
        dexterity: u8,
        vitality: u8,
        intelligence: u8,
        wisdom: u8,
        charisma: u8,
    );
}

#[starknet::interface]
pub trait ISettingsSystems<T> {
    fn add_settings(
        ref self: T,
        name: ByteArray,
        adventurer: Adventurer,
        bag: Bag,
        game_seed: u64,
        game_seed_until_xp: u16,
        in_battle: bool,
    ) -> u32;
    fn setting_details(self: @T, settings_id: u32) -> GameSettings;
    fn game_settings(self: @T, adventurer_id: u64) -> GameSettings;
    fn settings_count(self: @T) -> u32;
}

#[starknet::interface]
pub trait IGameTokenSystems<T> {
    // Standard ERC721 methods
    fn name(self: @T) -> ByteArray;
    fn symbol(self: @T) -> ByteArray;
    fn token_uri(self: @T, token_id: u256) -> ByteArray;
    fn balance_of(self: @T, account: ContractAddress) -> u256;
    fn owner_of(self: @T, token_id: u256) -> ContractAddress;

    // Game-specific methods
    fn adventurer_id(self: @T, token_id: u256) -> u64;
    fn token_id(self: @T, adventurer_id: u64) -> u256;
}

#[starknet::interface]
pub trait IElysiumDungeonGame<T> {
    fn create_dungeon_template(ref self: T, name: ByteArray, difficulty: u8) -> u32;
    fn spawn_new_adventure(ref self: T, settings_id: u32, weapon: u8) -> u64;
    fn get_dungeon_details(self: @T, settings_id: u32) -> GameSettings;
    fn get_player_adventures(self: @T, player: ContractAddress) -> Array<u64>;
}
