fn abs_u64(a: u64, b: u64) -> u64 {
    if a > b {
        return a - b;
    } else {
        return b - a;
    }
}

fn max_u64(a: u64, b: u64) -> u64 {
    if a > b {
        return a;
    } else {
        return b;
    }
}
