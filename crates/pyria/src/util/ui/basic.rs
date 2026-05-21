pub fn step(n: usize, total: usize, msg: &str) {
    println!("\n[{n}/{total}] {msg}");
}

pub fn ok(msg: &str) {
    println!("✓ {msg}");
}

pub fn working(msg: &str) {
    println!("… {msg}");
}

pub fn action(msg: &str) {
    println!("○ {msg}");
}

pub fn warn(msg: &str) {
    println!("! {msg}");
}

