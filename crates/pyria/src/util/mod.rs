


#[cfg(feature = "crypto")]
pub mod crypto;
#[cfg(feature = "core")]
pub mod sys;
pub mod ui;

#[cfg(feature = "crypto")]
use zeroize::Zeroizing;
#[cfg(feature = "crypto")]
pub fn unsize_zeroized_slice<const N: usize>(slice: Zeroizing<[u8; N]>) -> Zeroizing<Vec<u8>> {
    Zeroizing::new(slice.to_vec())
}