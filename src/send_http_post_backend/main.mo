import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Text "mo:base/Text";

//import the custom types we have in Types.mo
import Types "Types";

actor {

  //function to transform the response
  public query func transform(raw : Types.TransformArgs) : async Types.CanisterHttpResponsePayload {
      let transformed : Types.CanisterHttpResponsePayload = {
          status = raw.response.status;
          body = raw.response.body;
          headers = [
              {
                  name = "Content-Security-Policy";
                  value = "default-src 'self'";
              },
              { 
                name = "Referrer-Policy"; 
                value = "strict-origin" 
              },
              { 
                name = "Permissions-Policy"; 
                value = "geolocation=(self)" },
              {
                  name = "Strict-Transport-Security";
                  value = "max-age=63072000";
              },
              { 
                name = "X-Frame-Options"; 
                value = "DENY" 
              },
              { 
                name = "X-Content-Type-Options"; 
                value = "nosniff" 
              },
          ];
      };
      transformed;
  };

//PULIC METHOD
//This method sends a POST request to a URL with a free API we can test.
  public func send_http_post_request() : async Text {

    //1. DECLARE IC MANAGEMENT CANISTER
    //We need this so we can use it to make the HTTP request
    let ic : Types.IC = actor ("aaaaa-aa");

    //2. SETUP ARGUMENTS FOR HTTP GET request

    // 2.1 Setup the URL and its query parameters
    //This URL is used because it allows us to inspect the HTTP request sent from the canister
    let host : Text = "putsreq.com";
    let url = "https://putsreq.com/aL1QS5IbaQd4NTqN3a81"; //HTTP that accepts IPV6

    // 2.2 prepare headers for the system http_request call

    //idempotency keys should be unique so we create a function that generates them.
    let idempotency_key: Text = generateUUID();
    let request_headers = [
        { name = "Host"; value = host # ":443" },
        { name = "User-Agent"; value = "http_post_sample" },
        { name= "Content-Type"; value = "application/json" },
        { name= "Idempotency-Key"; value = idempotency_key }
    ];

 
    let request_body_json: Text = "{ \"name\" : \"ICP RWANDA\", \"force_sensitive\" : \"true\" }";
    let request_body_as_Blob: Blob = Text.encodeUtf8(request_body_json); 
    let request_body_as_nat8: [Nat8] = Blob.toArray(request_body_as_Blob); // e.g [34, 34,12, 0]


    // 2.2.1 Transform context
    let transform_context : Types.TransformContext = {
      function = transform;
      context = Blob.fromArray([]);
    };

    // 2.3 The HTTP request
    let http_request : Types.HttpRequestArgs = {
        url = url;
        max_response_bytes = null; //optional for request
        headers = request_headers;
        //note: type of `body` is ?[Nat8] so we pass it here as "?request_body_as_nat8" instead of "request_body_as_nat8"
        body = ?request_body_as_nat8; 
        method = #post;
        transform = ?transform_context;
    };

  
    Cycles.add(230_850_258_000);
    
    //4. MAKE HTTPS REQUEST AND WAIT FOR RESPONSE

    let http_response : Types.HttpResponsePayload = await ic.http_request(http_request);
    
   


    let response_body: Blob = Blob.fromArray(http_response.body);
    let decoded_text: Text = switch (Text.decodeUtf8(response_body)) {
        case (null) { "No value returned" };
        case (?y) { y };
    };

   
    let result: Text = decoded_text # ". See more info of the request sent at: " # url # "/inspect";
    result
  };


  func generateUUID() : Text {
    "UUID-123456789";
  }
};
