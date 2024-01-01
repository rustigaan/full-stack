use std::ffi::OsString;
use anyhow::{anyhow};
use std::fs;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    copy_proto()?;
    let serde = "#[derive(serde::Serialize, serde::Deserialize)]\n#[serde(default)]";
    tonic_build::configure().build_server(false)
        .out_dir("src")
        .message_attribute(".", serde)
        .compile(
        &["proto/proto_dendrite_config.proto"],
        &["proto"]
    )?;
    tonic_build::configure()
        .out_dir("src")
        .message_attribute(".", serde)
        .compile(
        &[
            "proto/proto_example.proto",
        ],
        &["proto"]
    )?;
    Ok(())
}

fn copy_proto() -> anyhow::Result<()> {
    fs::create_dir("proto").ok();
    match fs::read_dir("../proto") {
        Ok(proto_paths) => {
            for dir_entry_result in proto_paths {
                match dir_entry_result {
                    Ok(dir_entry) => {
                        copy_file(dir_entry.file_name(), "../proto", "proto")?
                    }
                    Err(e) => println!("Error in dir entry: {:?}", e)
                }
            }
        },
        Err(e) => println!("Could not read directory: ../proto: {:?}", e)
    };
    Ok(())
}

fn copy_file(name: OsString, from_dir: &str, to_dir: &str) -> anyhow::Result<()> {
    let mut from = OsString::from(from_dir);
    from.push("/");
    from.push(&name);
    let mut to = OsString::from(to_dir);
    to.push("/");
    to.push(&name);
    fs::copy(from, to).map(|_| ()).map_err(|e| anyhow!(e))
}