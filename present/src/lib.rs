use log::info;
use tonic_web_wasm_client::Client;
use wasm_bindgen::prelude::wasm_bindgen;
use wasm_bindgen_futures::spawn_local;
use yew::prelude::*;

pub mod proto_example {
    tonic::include_proto!("proto_example");
}

use crate::proto_example::greeter_service_client::GreeterServiceClient;
use crate::proto_example::Greeting;

#[function_component]
fn GreeterApp() -> Html {
    let counter = use_state(|| 0);
    let onclick = {
        spawn_local(call_greeter());
        let counter = counter.clone();
        move |_| {
            let value = *counter + 1;
            counter.set(value);
        }
    };

    html! {
        <div>
            <button {onclick}>{ "+1" }</button>
            <p>{ *counter }</p>
            <a href={"https://github.com/rustigaan/full-stack/tree/wasm"}>{"GitHub"}</a>
        </div>
    }
}

async fn call_greeter() -> () {
    info!("Call greeter");
    let greeting = Greeting { message: "Hello, World".to_string() };
    let base_url = "http://localhost:9001"; // URL of the gRPC-web server
    let mut greeter_client = GreeterServiceClient::new(Client::new(base_url.to_string()));
    match greeter_client.greet(greeting).await {
        Ok(response) => {
            let ack = response.into_inner();
            info!("Response: {ack:?}") },
        Err(err) => info!("Error: {err:?}"),
    };
}

#[wasm_bindgen(start)]
fn main() {
    wasm_logger::init(wasm_logger::Config::default());
    yew::Renderer::<GreeterApp>::new().render();
}
