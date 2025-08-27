use lambda_http::{run, service_fn, Body, Error, Request, RequestExt, Response};
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Serialize, Deserialize)]
struct GeoResponse {
    country: Option<String>,
    country_code: Option<String>,
    region: Option<String>,
    region_name: Option<String>,
    city: Option<String>,
    zip: Option<String>,
    lat: Option<f64>,
    lon: Option<f64>,
    timezone: Option<String>,
    isp: Option<String>,
    org: Option<String>,
    as_field: Option<String>,
    query: Option<String>,
    status: Option<String>,
    message: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct ErrorResponse {
    error: String,
    message: String,
}

async fn get_geolocation(ip: &str) -> Result<GeoResponse, Box<dyn std::error::Error>> {
    let url = format!("http://ip-api.com/json/{ip}");
    let response = reqwest::get(&url).await?;
    let geo_data: GeoResponse = response.json().await?;
    Ok(geo_data)
}

async fn function_handler(request: Request) -> Result<Response<Body>, Error> {
    // Get the request path
    let path = request.uri().path();
    
    // Handle both local development and production paths
    // Local: /geo, Production: /prod/geo, /v1/geo, etc.
    if path.ends_with("/geo") {
        handle_geolocation(request).await
    } else {
        handle_help().await // Any other endpoint returns help
    }
}

async fn handle_help() -> Result<Response<Body>, Error> {
    let help_content = json!({
        "message": "IP Geolocation API",
        "description": "Get geolocation information for IP addresses",
        "endpoints": {
            "/geo": "Get geolocation data for an IP address",
            "/": "Show this help information"
        },
        "usage": {
            "geolocation": "GET /geo?ip=8.8.8.8",
            "examples": [
                "GET /geo?ip=8.8.8.8",
                "GET /geo?ip=1.1.1.1",
                "GET /geo?ip=208.67.222.222"
            ]
        },
        "response_format": {
            "country": "Country name",
            "city": "City name", 
            "lat": "Latitude",
            "lon": "Longitude",
            "timezone": "Timezone",
            "isp": "Internet Service Provider"
        }
    });

    Ok(Response::builder()
        .status(200)
        .header("Content-Type", "application/json")
        .header("Access-Control-Allow-Origin", "*")
        .header("Access-Control-Allow-Methods", "GET, OPTIONS")
        .header("Access-Control-Allow-Headers", "Content-Type")
        .body(Body::from(serde_json::to_string(&help_content).unwrap()))
        .unwrap())
}

async fn handle_geolocation(request: Request) -> Result<Response<Body>, Error> {
    // Extract IP from query parameter or use a default
    let query_params = request.query_string_parameters();
    let ip = query_params.first("ip").unwrap_or("127.0.0.1");

    // Validate IP format (basic validation)
    if ip.parse::<std::net::IpAddr>().is_err() {
        let error_response = ErrorResponse {
            error: "Invalid IP".to_string(),
            message: format!("'{ip}' is not a valid IP address"),
        };
        
        return Ok(Response::builder()
            .status(400)
            .header("Content-Type", "application/json")
            .body(Body::from(serde_json::to_string(&error_response).unwrap()))
            .unwrap());
    }

    // Get geolocation data
    match get_geolocation(ip).await {
        Ok(geo_data) => {
            // Check if the API returned an error
            if geo_data.status.as_deref() == Some("fail") {
                let error_response = ErrorResponse {
                    error: "Geolocation lookup failed".to_string(),
                    message: geo_data.message.unwrap_or_else(|| "Unknown error".to_string()),
                };
                
                return Ok(Response::builder()
                    .status(400)
                    .header("Content-Type", "application/json")
                    .body(Body::from(serde_json::to_string(&error_response).unwrap()))
                    .unwrap());
            }

            // Return successful response
            Ok(Response::builder()
                .status(200)
                .header("Content-Type", "application/json")
                .header("Access-Control-Allow-Origin", "*")
                .header("Access-Control-Allow-Methods", "GET, OPTIONS")
                .header("Access-Control-Allow-Headers", "Content-Type")
                .body(Body::from(serde_json::to_string(&geo_data).unwrap()))
                .unwrap())
        }
        Err(e) => {
            let error_response = ErrorResponse {
                error: "Internal error".to_string(),
                message: format!("Failed to fetch geolocation data: {e}"),
            };
            
            Ok(Response::builder()
                .status(500)
                .header("Content-Type", "application/json")
                .body(Body::from(serde_json::to_string(&error_response).unwrap()))
                .unwrap())
        }
    }
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    // Initialize tracing only when dev-tracing feature is enabled
    #[cfg(feature = "dev-tracing")]
    {
        tracing_subscriber::fmt()
            .with_max_level(tracing::Level::INFO)
            .with_target(false)
            .without_time()
            .init();
    }

    run(service_fn(function_handler)).await
}
