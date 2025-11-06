import os
import azure.functions as func
from azure.cosmos import CosmosClient
import logging
import json

app = func.FunctionApp()

@app.route(route="VisitorCounter", auth_level=func.AuthLevel.ANONYMOUS)
def VisitorCounter(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Processing visitor counter request.')

    # --- Cosmos DB configuration ---
    counter_id = "visitors"

    COSMOS_URI = os.environ["COSMOS_URI"] 
    COSMOS_KEY = os.environ["COSMOS_KEY"]
    DATABASE_NAME = os.environ["DATABASE_NAME"]
    CONTAINER_NAME = os.environ["CONTAINER_NAME"]

    # --- Initialize Cosmos DB client ---
    client = CosmosClient(COSMOS_URI, credential=COSMOS_KEY)
    database = client.get_database_client(DATABASE_NAME)
    container = database.get_container_client(CONTAINER_NAME)

    # --- Read or create the counter ---
    try:
        item = container.read_item(item=counter_id, partition_key=counter_id)
        item["count"] += 1
        container.replace_item(item=counter_id, body=item)
        count = item["count"]
        logging.info(f"Visitor count updated to {count}")
    except Exception as e:
        logging.warning(f"Counter not found, creating a new one: {e}")
        item = {"id": counter_id, "count": 1}
        container.create_item(body=item)
        count = 1

    # --- Return response ---
    response = {"visits": count}
    return func.HttpResponse(
        json.dumps(response),
        status_code=200,
        mimetype="application/json"
    )
