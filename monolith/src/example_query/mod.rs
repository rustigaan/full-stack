use crate::proto_example::{Greeting, SearchQuery, SearchResponse};
use anyhow::{Context, Result};
use dendrite::axon_server::query::QueryRequest;
use dendrite::axon_utils::{axon_serialize, empty_handler_registry, query_processor, AxonServerHandle, HandlerRegistry, QueryContext, QueryResult, TheHandlerRegistry, WorkerControl};
use dendrite::mongodb::{MongoCollectionQueryModel,create_mongodb_collection_query_model,wait_for_mongodb};
use dendrite::macros as dendrite_macros;
use futures_util::TryStreamExt;
use log::{debug, error};
use mongodb::bson::doc;
use prost::Message;

#[derive(Clone)]
struct ExampleQueryContext(MongoCollectionQueryModel);

impl QueryContext for ExampleQueryContext {}

/// Handles queries.
///
/// Constructs an query handler registry and delegates to function `query_processor`.
pub async fn process_queries(url: &str, axon_server_handle: AxonServerHandle, worker_control: WorkerControl) {
    if let Err(e) = internal_process_queries(url, axon_server_handle, worker_control).await {
        error!("Error while handling queries: {:?}", e);
    }
    debug!("Stopped handling queries");
}

async fn internal_process_queries(url: &str, axon_server_handle: AxonServerHandle, worker_control: WorkerControl) -> Result<()> {
    let client = wait_for_mongodb(url, "Example").await?;
    debug!("MongoDB client: {:?}", client);

    let mongo_query_model = create_mongodb_collection_query_model("example", client, "grok", "greeting");
    let query_context = ExampleQueryContext(mongo_query_model);

    let mut query_handler_registry: TheHandlerRegistry<
        ExampleQueryContext,
        QueryRequest,
        QueryResult,
    > = empty_handler_registry();

    query_handler_registry.register(&handle_search_query)?;

    query_processor(axon_server_handle, query_context, query_handler_registry, worker_control)
        .await
        .context("Error while handling queries")
}

#[dendrite_macros::query_handler]
async fn handle_search_query(
    search_query: SearchQuery,
    query_model: ExampleQueryContext,
) -> Result<Option<QueryResult>> {
    let filter = doc! {
        "greeting": {
            "$regex": search_query.query.clone()
        }
    };
    let mut search_response = query_model.0.get_collection().find(Some(filter), None).await?;
    let mut greetings = Vec::new();
    while let Some(item) = search_response.try_next().await? {
        debug!("Search response item: {:?}", item);
        let greeting = Greeting {
            message: item.get_str("greeting")?.to_string(),
        };
        greetings.push(greeting);
    }
    let greeting = Greeting {
        message: "Test!".to_string(),
    };
    greetings.push(greeting);
    let response = SearchResponse { greetings };
    let result = axon_serialize("SearchResponse", &response)?;
    let query_result = QueryResult {
        payload: Some(result),
    };
    Ok(Some(query_result))
}
