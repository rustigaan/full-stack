use leptos::*;
use log::{error, info};
use tonic_web_wasm_client::Client;
use wasm_bindgen_futures::spawn_local;

pub mod proto_example {
    tonic::include_proto!("proto_example");
}

use crate::proto_example::greeter_service_client::GreeterServiceClient;
use crate::proto_example::Greeting;

#[component]
fn GreeterApp() -> impl IntoView {
    let (greeting, set_greeting) = create_signal("".to_string());
    let oninput =
        move |input_event| { set_greeting.set(event_target_value(&input_event)); };
    let (counter, set_counter) = create_signal(0);
    let (acknowledgement, set_acknowledgement) = create_signal("".to_string());
    let onclick =
        move |_| {
            spawn_local(call_greeter(greeting.get().clone(), set_acknowledgement));
            set_counter.update(|value| *value += 1);
        };

    view! {
        <div>
            <h1>Rust Frontend Example with Leptos</h1>
            <div>
                <input on:input=oninput/>
                <button on:click=onclick>{ "+1" }</button>
                {" Count: "}{counter}
            </div>
            <div>{"Greeting: ["}{greeting}{"]"}</div>
            <div>{"Acknowledgement from back-end: ["}{acknowledgement}{"]"}</div>
            <div class={"footer"}>
                <a href={"https://github.com/rustigaan/full-stack"} target={"_blank"}>{"🦀 GitHub 🦀"}</a>
            </div>
        </div>
    }
}

async fn call_greeter(greeting: String, set_acknowledgement: WriteSignal<String>) -> () {
    info!("Call greeter");
    let greeting = Greeting { message: greeting };
    let base_url = "http://localhost:3000"; // URL of the gRPC-web server
    let mut greeter_client = GreeterServiceClient::new(Client::new(base_url.to_string()));
    match greeter_client.greet(greeting).await {
        Ok(response) => {
            let ack = response.into_inner();
            info!("Response: {ack:?}");
            set_acknowledgement.set(ack.message);
        },
        Err(err) => error!("Error: {err:?}"),
    };
}

fn main() {
    _ = console_log::init_with_level(log::Level::Debug);
    mount_to_body(|| view! { <GreeterApp/> })
}