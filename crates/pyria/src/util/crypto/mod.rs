use hkdf::Hkdf;
use zeroize::Zeroizing;
use anyhow::Result;
use sha2::{Sha256, Digest};
use rand::Rng;

pub mod argon2id;
pub use argon2id::argon2id;
pub mod fido2;
pub mod key;
pub mod tpm2;
pub mod luks;

const HKDF_DERIVATION_KEY: &[u8] = b"pyria:hkdf:derivation:v1";
const HKDF_FINALIZATION_KEY: &[u8] = b"pyria:hkdf:finalization:v1";

pub(crate) type Pin = Zeroizing<Option<String>>;

pub fn hkdf_merge(salts: Zeroizing<Vec<[u8; 32]>>) -> Result<Zeroizing<[u8; 32]>> {
  if salts.is_empty() {
    return Err(anyhow::anyhow!("salts is empty?"));
  }
  if salts.len() == 1 {
    return Ok(Zeroizing::new(salts[0]));
  }
  let mut combined_salt = Zeroizing::new([0u8; 32]);
  let mut left = Zeroizing::new(salts[0]);
  for salt in salts.iter().skip(1) {
      let hkdf = Hkdf::<Sha256>::new(Some(left.as_ref()), salt.as_ref());
      hkdf.expand(HKDF_DERIVATION_KEY, &mut *combined_salt)?;
      left = Zeroizing::new(*combined_salt);
  }
  Ok(combined_salt)
}

pub fn hkdf_finalize_key<const KEY_SIZE: usize>(
    salt: Zeroizing<[u8; 32]>,
    info: Zeroizing<[u8; 32]>,
) -> Result<Zeroizing<[u8; KEY_SIZE]>> {
    let mut key = Zeroizing::new([0u8; KEY_SIZE]);
    let hkdf = Hkdf::<Sha256>::new(Some(salt.as_ref()), info.as_ref());
    hkdf.expand(HKDF_FINALIZATION_KEY, &mut *key)?;
    Ok(key)
}

pub fn secure_random<const N: usize>() -> Zeroizing<[u8; N]> {
    let mut bytes = Zeroizing::new([0u8; N]);
    rand::rng().fill_bytes(&mut *bytes);
    bytes
}

pub fn sha256(data: Zeroizing<Vec<u8>>) -> Zeroizing<[u8; 32]> {
  Zeroizing::new(Sha256::digest(data.as_slice()).into())
}
