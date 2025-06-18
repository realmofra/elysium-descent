pub struct CharacterMovementConfig;

impl CharacterMovementConfig {
    pub const MAX_SLOPE_ANGLE: f32 = 45.0;
    pub const STAIR_HEIGHT: f32 = 0.6;
    pub const GROUND_SNAP_DISTANCE: f32 = 0.2;
    pub const MOVEMENT_ACCELERATION: f32 = 30.0;
    pub const MOVEMENT_DECELERATION: f32 = 40.0;
    pub const MAX_SPEED: f32 = 5.0;
    pub const ROTATION_SPEED: f32 = 5.0;
}
