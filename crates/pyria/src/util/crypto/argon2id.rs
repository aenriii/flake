use argon2::{Algorithm, Argon2, Params, Version};
use zeroize::Zeroizing;

use crate::{crypto::secure_random, ui};

pub const DEFAULT_PARAMS: Params = match Params::new(
  1024 * 1024 * 8, // 8 GiB
  3,
  4,
  Some(32)
) {
    Ok(params) => params,
    Err(_) => panic!("Params::new failed") // unreachable, params verification is hardcoded
};

#[cfg(test)]
pub const TEST_PARAMS: Params = match Params::new(
  1024 * 32, // 32 MiB
  3,
  4,
  Some(32)
) {
    Ok(params) => params,
    Err(_) => panic!("Params::new failed") // unreachable, params verification is hardcoded
};

pub fn argon2id(data: Zeroizing<Vec<u8>>, salt: Zeroizing<[u8; 32]>, params: Option<Params>) -> anyhow::Result<Zeroizing<Vec<u8>>> {
    let params = params.unwrap_or(DEFAULT_PARAMS);
    let mut output = Zeroizing::new(vec![0u8; params.output_len().unwrap_or(32)]);
    Argon2::new(Algorithm::Argon2id, Version::V0x13, params)
        .hash_password_into(data.as_ref(), salt.as_ref(), &mut *output)
        .map_err(|e| anyhow::anyhow!(e))?;
    Ok(output)
}
/// find the target parameters for a given memory cost and goal seconds on a given machine
pub fn find_target_params(memory_cost: u32, goal_seconds: u32) -> anyhow::Result<Params> {
  let mut iterations = 1;
  let mut secs;
  while {
    ui::step(iterations, 16, &format!("testing {} iterations...", iterations));
    let stopwatch = std::time::Instant::now();
    let params = Params::new(memory_cost, iterations as u32, 4, Some(32))
      .map_err(|it| anyhow::anyhow!(it))?;
    let rand = Zeroizing::new(secure_random::<64>().to_vec());
    let salt = secure_random::<32>();
    let _hash = argon2id(rand, salt, Some(params));
    secs = stopwatch.elapsed().as_secs_f64();
    ui::working(&format!("{} iterations took {} seconds...", iterations, secs));
    secs < (goal_seconds as f64 / 1.5)
  } && iterations < 16 {
    iterations += 2;
  }
  ui::ok(&format!("success! {} iterations took {} seconds", iterations, secs));
  Ok(Params::new(memory_cost, 3, iterations as u32, Some(32)).unwrap())
}