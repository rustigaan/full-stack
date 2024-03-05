use log::{error, info};
use tonic_web_wasm_client::Client;
use wasm_bindgen::prelude::wasm_bindgen;
use wasm_bindgen::{JsCast, UnwrapThrowExt};
use wasm_bindgen_futures::spawn_local;
use web_sys::HtmlInputElement;
use yew::prelude::*;

pub mod proto_example {
    tonic::include_proto!("proto_example");
}

use crate::proto_example::greeter_service_client::GreeterServiceClient;
use crate::proto_example::Greeting;

#[function_component]
fn GreeterApp() -> Html {
    let greeting = use_state(|| "".to_string());
    let oninput = {
        let greeting = greeting.clone();
        move |input_event: InputEvent| {
            let target: HtmlInputElement = input_event
                .target()
                .unwrap_throw()
                .dyn_into()
                .unwrap_throw();
            greeting.set(target.value());
        }
    };
    let counter = use_state(|| 0);
    let onclick = {
        let greeting = greeting.clone();
        let counter = counter.clone();
        move |_| {
            spawn_local(call_greeter((*greeting).clone()));
            let value = *counter + 1;
            counter.set(value);
        }
    };

    html! {
        <div>
            <div>
                <input type={"text"} {oninput}/>
                <button {onclick}>{ "+1" }</button>
                <p>{ *counter }</p>
            </div>
            <div>
                {&*greeting}
            </div>
            <div class={"footer"}>
                <a href={"https://github.com/rustigaan/full-stack/tree/wasm"}>{"🦀 GitHub 🦀"}</a>
            </div>
        </div>
    }
}

async fn call_greeter(greeting: String) -> () {
    info!("Call greeter");
    let greeting = Greeting { message: greeting };
    let base_url = "http://localhost:3000"; // URL of the gRPC-web server
    let mut greeter_client = GreeterServiceClient::new(Client::new(base_url.to_string()));
    match greeter_client.greet(greeting).await {
        Ok(response) => {
            let ack = response.into_inner();
            info!("Response: {ack:?}") },
        Err(err) => error!("Error: {err:?}"),
    };
}

#[wasm_bindgen(start)]
fn main() {
    wasm_logger::init(wasm_logger::Config::default());
    yew::Renderer::<GreeterApp>::new().render();
}
