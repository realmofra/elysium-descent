pub struct CharacterMovementConfig;

impl CharacterMovementConfig {
    pub const MAX_SLOPE_ANGLE: f32 = 45.0;
    pub const STAIR_HEIGHT: f32 = 0.6;
    pub const GROUND_SNAP_DISTANCE: f32 = 0.2;
    pub const MOVEMENT_ACCELERATION: f32 = 30.0;
    pub const MOVEMENT_DECELERATION: f32 = 40.0;
    pub const MAX_SPEED: f32 = 5.0;
    pub const ROTATION_SPEED: f32 = 5.0;
    
    // Air and ground friction constants
    pub const AIR_RESISTANCE: f32 = 0.98;
    pub const GROUND_FRICTION: f32 = 0.92;
    
    // Movement threshold for stopping tiny residual movement
    pub const MIN_MOVEMENT_THRESHOLD: f32 = 0.01;
}
