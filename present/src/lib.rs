use wasm_bindgen::prelude::wasm_bindgen;
use yew::prelude::*;

#[function_component]
fn GreeterApp() -> Html {
    let counter = use_state(|| 0);
    let onclick = {
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

#[wasm_bindgen(start)]
fn main() {
    yew::Renderer::<GreeterApp>::new().render();
}
