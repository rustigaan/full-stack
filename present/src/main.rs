use leptos::*;
use log::{error, info};
use tonic::codegen::tokio_stream::StreamExt;
use tonic_web_wasm_client::Client;
use wasm_bindgen_futures::spawn_local;

pub mod proto_example {
    tonic::include_proto!("proto_example");
}

use crate::proto_example::greeter_service_client::GreeterServiceClient;
use crate::proto_example::{Empty, Greeting};

#[component]
fn GreeterApp() -> impl IntoView {
    let (greeting, set_greeting) = create_signal("".to_string());
    let oninput =
        move |input_event| { set_greeting.set(event_target_value(&input_event)); };
    let (counter, set_counter) = create_signal(0);
    let (acknowledgement, set_acknowledgement) = create_signal("".to_string());
    let (greetings, set_greetings) = create_signal(Vec::<String>::new());
    let onclick_call_greeter =
        move |_| {
            spawn_local(call_greeter(greeting.get().clone(), set_acknowledgement));
            set_counter.update(|value| *value += 1);
        };
    let onclick_fetch_greetings =
        move |_| {
            spawn_local(fetch_greetings(set_greetings));
        };

    view! {
        <div>
            <h1>Rust Frontend Example with Leptos</h1>
            <div>
                <input on:input=oninput/>
                <button on:click=onclick_call_greeter>{ "+1" }</button>
                {" Count: "}{counter}
            </div>
            <div>{"Greeting: ["}{greeting}{"]"}</div>
            <div>{"Acknowledgement from back-end: ["}{acknowledgement}{"]"}</div>
            <div>
                <button on:click=onclick_fetch_greetings>{ "Fetch greetings" }</button>
                <ul>
                    <For each=move || greetings.get()
                         key=|g| g.clone()
                         children=move |s| view! { <li>{s}</li> }
                    />
                </ul>
            </div>
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

async fn fetch_greetings(set_greetings: WriteSignal<Vec<String>>) -> () {
    info!("Fetch greetings");
    let empty = Empty {};
    let base_url = "http://localhost:3000"; // URL of the gRPC-web server
    let mut greeter_client = GreeterServiceClient::new(Client::new(base_url.to_string()));
    match greeter_client.greetings(empty).await {
        Ok(response) => {
            let greetings = response.into_inner();
            let mapped = greetings.map(greeting_result_to_string).filter(|s| !s.is_empty());
            let collected = mapped.collect::<Vec<String>>().await;
            info!("Response: {collected:?}");
            set_greetings.set(collected);
        },
        Err(err) => error!("Error: {err:?}"),
    };
}

fn greeting_result_to_string<E>(greeting: Result<Greeting,E>) -> String {
    greeting.ok().map(|g| g.message).unwrap_or("".to_string())
}

fn main() {
    _ = console_log::init_with_level(log::Level::Debug);
    mount_to_body(|| view! { <GreeterApp/> })
}