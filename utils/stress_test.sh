#!/bin/bash
# Originally written 2026-02-20
# Concurrency test for CPU based inferencing

# --- Configuration ---
export NAI_URL=""
export API_KEY=""
export NAI_EP="llama-32-3b"
export PROMPT="help me plan a trip to Paris"
export URL="https://$NAI_URL/enterpriseai/v1/chat/completions"
export CSV_FILE="summary.csv"
export RAW_LOG="results.txt"

# Define the concurrency levels you want to test (separated by spaces)
TEST_LEVELS=(10 20 30 40 50)

# Initialize CSV header if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "TIMESTAMP,CONCURRENCY,MIN,MAX,AVG,FAILURES" > "$CSV_FILE"
fi

echo "--- Starting Automated Load Test ---"
echo "Testing levels: ${TEST_LEVELS[*]}"

for CONCURRENCY in "${TEST_LEVELS[@]}"; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "------------------------------------------------"
    echo "[$TIMESTAMP] Testing Concurrency: $CONCURRENCY"
    
    # Clear the temporary raw log for this specific run
    > "$RAW_LOG"

    # Fire the parallel requests
    for i in $(seq 1 "$CONCURRENCY"); do
        curl -k -s -o /dev/null -X 'POST' "$URL" \
            -w "%{time_total} %{http_code}\n" \
            -H 'accept: application/json' \
            -H "Authorization: Bearer $API_KEY" \
            -H 'Content-Type: application/json' \
            -d "{
                \"model\": \"$NAI_EP\",
                \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}],
                \"max_tokens\": 256,
                \"stream\": false
            }" >> "$RAW_LOG" &
    done

    # Wait for this batch to finish
    wait

    # Calculate stats and append to CSV/Console
    awk -v ts="$TIMESTAMP" -v conc="$CONCURRENCY" -v wall="$TOTAL_WALL_TIME" '
    BEGIN { failures=0; count=0; sum=0; }
    /^[0-9]/ {
        time=$1; status=$2;
        if (status < 200 || status >= 300) failures++;
        if (count == 0) { min=time; max=time; }
        if (time < min) min=time;
        if (time > max) max=time;
        sum += time;
        count++;
    }
    END {
        avg = (count > 0) ? sum/count : 0;
        rps = (wall > 0) ? count/wall : 0;
        
        # 1. Print human-readable summary to the terminal
        printf "Result: Avg %.4fs | RPS: %.2f | Failures: %d\n", avg, rps, failures > "/dev/stderr"
        
        # 2. Print the CSV row to standard output
        printf "%s,%d,%.4f,%.4f,%.4f,%d,%.2f\n", ts, conc, min, max, avg, failures, rps
    }' "$RAW_LOG" >> "$CSV_FILE"

    # Optional: Short sleep to let the server "breathe" between batches
    sleep 2
done

echo "------------------------------------------------"
echo "All tests complete. Open $CSV_FILE to see the full comparison."