
#!/bin/bash

TOKEN_TYPE=$1
# Extract the Id of series or group tokens from the input

while IFS= read -r line; do
    # Check if the line contains "Type" and if the next line should be read
    if [[ $line == *"Type"* && $line == *$TOKEN_TYPE* ]]; then
        read_next_line=true
    elif [ "$read_next_line" = true ]; then
        # If the next line should be read and contains "Id", extract and print the Id
        if [[ $line == "Id"* ]]; then
            echo "$line" | awk '{print $NF}'
        fi
        read_next_line=false
    fi
done < /dev/stdin # Read from stdin
