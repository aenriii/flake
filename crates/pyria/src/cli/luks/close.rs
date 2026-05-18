use crate::ui;
use crate::crypto::luks::Luks2DeviceWrapper;

pub fn run(device: &str, header_file: Option<&str>) -> anyhow::Result<()> {
    let name = super::mapper_name(device);

    ui::working(format!("closing /dev/mapper/{name}...").as_str());
    Luks2DeviceWrapper::deactivate_by_name(&name, header_file.map(std::path::Path::new))?;
    ui::ok(format!("{name} closed").as_str());
    Ok(())
}
