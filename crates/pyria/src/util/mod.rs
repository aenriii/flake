use zeroize::Zeroizing;

pub mod crypto;
pub mod sys;
pub mod ui;

pub fn unsize_zeroized_slice<const N: usize>(slice: Zeroizing<[u8; N]>) -> Zeroizing<Vec<u8>> {
    Zeroizing::new(slice.to_vec())
}