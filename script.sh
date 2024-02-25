#!/bin/bash

# The selected text to be summarized, passed as the first argument
SELECTED_TEXT="$1"

# Exit early if no text is provided
if [ -z "$SELECTED_TEXT" ]; then
  exit 0
fi

# Keychain service name
SERVICE_NAME="right_click_summarize_openai_api_key"
# Log file path
LOG_FILE="/tmp/right_click_summarize_script.log"

# Start logging
echo "Starting script..." > "$LOG_FILE"

# Try to retrieve the API key from the Keychain
API_KEY=$(security find-generic-password -a $USER -s "$SERVICE_NAME" -w 2>/dev/null)

if [ -z "$API_KEY" ]; then
  echo "API key not found in Keychain." >> "$LOG_FILE"
  osascript -e 'Tell application "System Events" to display dialog "API key not found. Please configure your API key." with title "Error"'
  exit 1
else
  echo "API key successfully retrieved." >> "$LOG_FILE"
fi

# The selected text to be summarized, passed as the first argument
SELECTED_TEXT="$1"

# URL for the OpenAI Chat Completion API
API_URL="https://api.openai.com/v1/chat/completions"

# System prompt
SYSTEM_PROMPT="You are an expert summarizer. Your task is to save time for the user. A summary can be MAXIMUM two sentences long, capturing the absolutely most important things."

# Prepare the data for the API request using the full path to jq
JSON_DATA=$(/opt/homebrew/bin/jq -n \
                  --arg systemPrompt "$SYSTEM_PROMPT" \
                  --arg userPrompt "Please summarize this for me: $SELECTED_TEXT" \
                  '{model: "gpt-4-turbo-preview", messages: [{role: "system", content: $systemPrompt}, {role: "user", content: $userPrompt}], temperature: 0}')

# Make the API request and capture the HTTP status code and response body
HTTP_RESPONSE=$(curl -s -o response.json -w "%{http_code}" -X POST "$API_URL" \
                 -H "Content-Type: application/json" \
                 -H "Authorization: Bearer $API_KEY" \
                 --data "$JSON_DATA")

# Check if the request was successful
if [ "$HTTP_RESPONSE" != "200" ]; then
  # Log the HTTP status code
  echo "API request failed with response code: $HTTP_RESPONSE" >> "$LOG_FILE"
  # Log the error response body
  echo "Error response from API:" >> "$LOG_FILE"
  cat response.json >> "$LOG_FILE"
  osascript -e 'Tell application "System Events" to display dialog "Failed to get a summary from OpenAI. Please check your internet connection and API key. For more information, check the log file at /tmp/right_click_summarize_script.log" with title "Error"'
  exit 1
else
  echo "API request successful." >> "$LOG_FILE"
fi

# Extract the summary from the response using the full path to jq
SUMMARY=$(/opt/homebrew/bin/jq -r '.choices[0].message.content' response.json)

if [ -z "$SUMMARY" ]; then
  echo "Failed to extract summary." >> "$LOG_FILE"
  osascript -e 'Tell application "System Events" to display dialog "Failed to extract summary from the response." with title "Error"'
  exit 1
else
  echo "Summary extracted successfully." >> "$LOG_FILE"
fi

# Use osascript to display the dialog and capture the button pressed by the user
BUTTON_PRESSED=$(osascript <<EOF
tell application "System Events"
    set userChoice to button returned of (display dialog "$SUMMARY" buttons {"OK", "Copy Text"} default button "OK" with title "Summary")
    return userChoice
end tell
EOF
)

# Check the button pressed by the user
if [ "$BUTTON_PRESSED" = "Copy Text" ]; then
    echo "$SUMMARY" | pbcopy
    echo "Summary copied to clipboard."
else
    echo "OK pressed or dialog closed."
fi