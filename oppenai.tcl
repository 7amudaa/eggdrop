package require http
package require json


# Replace this with a secure method to load the API key
proc get_api_key {} {
	# Visit: https://beta.openai.com/account/api-keys
    return "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"
}
# Define the trigger command
set trigger_cmd "!openai"

# Replace this with a secure method to load the endpoint
proc get_endpoint {} {
    return "https://api.openai.com/v1/engines/davinci-codex/completions"
}

# Load the API key and endpoint from a secure location
set api_key [get_api_key]
set endpoint [get_endpoint]

# Bind to the pub and msg events
bind pub -|- openai_response
bind msg -|- openai_response

proc openai_response {nick host hand chan text} {
    # Check if the text matches the trigger command
    if {[string match "$trigger_cmd*" $text]} {
        # Extract the prompt from the text
        set prompt [string trim [string range $text [string length $trigger_cmd] end]]

        # Set the payload for the HTTP request
        set payload [http::formatQuery prompt $prompt api_key $api_key]

        # Set the headers for the HTTP request
        set headers [list Content-Type "application/json"]

        # Make the HTTP request
        if {[catch {set query_result [http::data -headers $headers -body $payload $endpoint]} error]} {
            putlog "Error making HTTP request: $error"
            return
        }

        # Parse the JSON response
        if {[catch {set json_result [json::json2dict $query_result]} error]} {
            putlog "Error parsing JSON response: $error"
            return
        }

        # Get the response text from the JSON result
        set response [dict get $json_result "choices" 0 "text"]

        # Send the response to the channel
        if {$response == ""} {
            send_response $chan "Sorry, I couldn't understand your question"
        } else {
            send_response $chan "$response"
        }
    }
}

# A helper procedure to send a response to the channel
proc send_response {chan text} {
    putserv "PRIVMSG $chan :$text"
}

