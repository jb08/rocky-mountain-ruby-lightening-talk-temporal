use std::str::FromStr;

use temporalio_client::{Client, ClientOptions, Connection, ConnectionOptions, Url};
use temporalio_macros::activities;
use temporalio_sdk::{
    activities::{ActivityContext, ActivityError},
    Runtime, Worker, WorkerOptions,
};

struct BackgroundCheckActivities;

#[activities]
impl BackgroundCheckActivities {
    // Named to match the wire activity type the Ruby workflow already sends
    // (Temporalio::Activity::Definition defaults to the class's unqualified
    // name -- "HandlePossibleFcraDisputeActivity") so this Rust worker can
    // pick up the task the Ruby workflow routes to it.
    #[activity(name = "HandlePossibleFcraDisputeActivity")]
    pub(crate) async fn handle_possible_fcra_dispute(
        _ctx: ActivityContext,
        candidate_name: String,
    ) -> Result<String, ActivityError> {
        Ok(format!(
            "FCRA dispute check for {candidate_name}: no dispute filed, process complete (via Rust worker)"
        ))
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let raw_address =
        std::env::var("TEMPORAL_ADDRESS").unwrap_or_else(|_| "localhost:7233".to_string());
    let address = if raw_address.starts_with("http") {
        raw_address
    } else {
        format!("http://{raw_address}")
    };
    let namespace = std::env::var("TEMPORAL_NAMESPACE").unwrap_or_else(|_| "default".to_string());
    let task_queue = std::env::var("TEMPORAL_RUST_TASK_QUEUE")
        .unwrap_or_else(|_| "background-check-rust".to_string());

    let connection_options = ConnectionOptions::new(Url::from_str(&address)?).build();
    let runtime = Runtime::from_current_tokio(Default::default())?;
    let connection = Connection::connect(connection_options).await?;
    let client = Client::new(connection, ClientOptions::new(namespace).build())?;

    let worker_options = WorkerOptions::new(task_queue.clone())
        .register_activities(BackgroundCheckActivities)
        .build();

    let mut worker = Worker::new(&runtime, client, worker_options)?;

    println!("Starting Rust Temporal worker on task queue '{task_queue}'...");
    worker.run().await?;

    Ok(())
}
