use dojo_starter::utils::{abs_u64, max_u64};

#[derive(Serde, Copy, Drop, Introspect)]
pub struct Vec2 {
    pub x: u64,
    pub y: u64,
}

#[generate_trait]
impl Vec2Impl of Vec2Trait {
    fn is_zero(self: Vec2) -> bool {
        if self.x - self.y == 0 {
            return true;
        }
        false
    }

    fn is_equal(self: Vec2, b: Vec2) -> bool {
        self.x == b.x && self.y == b.y
    }

    fn chebyshev_distance(self: Vec2, p2: Vec2) -> u64 {
        let dx = abs_u64(self.x, p2.x);
        let dy = abs_u64(self.y, p2.y);

        return max_u64(dx, dy);
    }
}
