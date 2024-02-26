fn main() -> Result<(), Box<dyn std::error::Error>> {
    let serde = "#[derive(serde::Serialize, serde::Deserialize)]\n#[serde(default)]";
    tonic_build::configure()
        .build_transport(false)
        .build_server(false)
        .message_attribute(".", serde)
        .compile(
        &[
            "proto/proto_example.proto",
        ],
        &["proto"]
    )?;
    Ok(())
}
