use anyhow::Context;
use fido2_rs::{
    assertion::AssertRequest,
    credentials::{CoseType, Credential, Extensions, Opt},
    device::{Device, DeviceInfo, DeviceList},
};
use sha2::{Digest, Sha256};
use zeroize::Zeroizing;

const RP_ID: &str = "pyria";
const CLIENT_DATA: &[u8] = b"pyria:fido:client-data:v1";

/// personalization input used to derive a per-credential deterministic salt from the device
pub const HMAC_SALT_INPUT: &[u8] = b"pyria:fido2:salt:v1";

fn new_credential() -> anyhow::Result<Credential> {
  let mut cred = Credential::new();
  cred.set_client_data(CLIENT_DATA)
      .map_err(|e| anyhow::anyhow!("set client data: {e}"))?;
  cred.set_rp(RP_ID, "pyria disk encryption")
      .map_err(|e| anyhow::anyhow!("set rp: {e}"))?;
  cred.set_user(b"pyria-disk", "pyria-disk", None, None)
      .map_err(|e| anyhow::anyhow!("set user: {e}"))?;
  cred.set_cose_type(CoseType::ES256)
      .map_err(|e| anyhow::anyhow!("set cose type: {e}"))?;
  cred.set_extension(Extensions::HMAC_SECRET)
      .map_err(|e| anyhow::anyhow!("set extension: {e}"))?;
  cred.set_rk(Opt::False)
      .map_err(|e| anyhow::anyhow!("set rk: {e}"))?;
  Ok(cred)
}

fn assert_request(credential: &Credential) -> anyhow::Result<AssertRequest> {
  let mut request = AssertRequest::new();
  request
      .set_rp(RP_ID)
      .map_err(|e| anyhow::anyhow!("set rp: {e}"))?;
  request
      .set_client_data(CLIENT_DATA)
      .map_err(|e| anyhow::anyhow!("set client data: {e}"))?;
  request
      .set_allow_credential(credential.id())
      .map_err(|e| anyhow::anyhow!("set allow credential: {e}"))?;
  request
      .set_extensions(Extensions::HMAC_SECRET)
      .map_err(|e| anyhow::anyhow!("set extensions: {e}"))?;
  request
      .set_uv(Opt::True)
      .map_err(|e| anyhow::anyhow!("set uv: {e}"))?;
  request
      .set_up(Opt::True)
      .map_err(|e| anyhow::anyhow!("set up: {e}"))?;
  Ok(request)
}

/// Find a FIDO2 device, optionally filtered by a predicate.
/// Returns the device and whether it requires a PIN.
pub fn device(filter: Option<Box<dyn Fn(&DeviceInfo) -> bool>>) -> anyhow::Result<(Device, bool)> {
  let list = DeviceList::list_devices(8);
  let mut infos = list.into_iter();
  let info = if let Some(filter) = filter {
    infos.filter(filter).next().ok_or(anyhow::anyhow!("no matching FIDO2 device found"))?
  } else {
    infos.next().ok_or(anyhow::anyhow!("no FIDO2 device found"))?
  };
  let device = info.open().context("failed to open FIDO2 device")?;
  let has_pin = device.has_pin();
  Ok((device, has_pin))
}

/// Register a new FIDO2 credential on the device.
/// Returns the credential ID bytes to be stored in key metadata.
pub fn enroll(device: &Device, pin: super::Pin) -> anyhow::Result<Vec<u8>> {
  let mut cred = new_credential()?;
  device
      .make_credential(&mut cred, (*pin).as_deref())
      .map_err(|e| anyhow::anyhow!("make_credential failed: {e}"))?;
  Ok(cred.id().to_vec())
}

/// Get the deterministic HMAC-SECRET output for a given input using a full `Credential`.
pub fn hmac(device: &Device, credential: &Credential, pin: super::Pin, input: &[u8]) -> anyhow::Result<Zeroizing<[u8; 32]>> {
  let mut request = assert_request(credential)?;

  // FIDO2 HMAC-SECRET requires exactly 32 bytes; hash the input to get there
  let hashed = Sha256::digest(input);
  request
      .set_hmac_salt(hashed.as_slice())
      .map_err(|e| anyhow::anyhow!("set hmac salt: {e}"))?;

  let assertions = device
      .get_assertion(request, (*pin).as_deref())
      .map_err(|e| anyhow::anyhow!("get_assertion failed: {e}"))?;

  let assertion = assertions
      .iter()
      .next()
      .ok_or_else(|| anyhow::anyhow!("no assertions returned by FIDO2 device"))?;

  let mut out = Zeroizing::new([0u8; 32]);
  let secret = assertion.hmac_secret();
  if secret.len() != 32 {
    return Err(anyhow::anyhow!("hmac secret is not 32 bytes (got {})", secret.len()));
  }
  out.copy_from_slice(&secret);
  Ok(out)
}

/// Get the deterministic HMAC-SECRET output using a stored credential ID instead of a full `Credential`.
pub fn hmac_with_id(
  device: &Device,
  cred_id: &[u8],
  pin: super::Pin,
  input: &[u8],
) -> anyhow::Result<Zeroizing<[u8; 32]>> {
  let mut cred = Credential::new();
  cred.set_id(cred_id)
      .map_err(|e| anyhow::anyhow!("set credential id: {e}"))?;
  hmac(device, &cred, pin, input)
}
