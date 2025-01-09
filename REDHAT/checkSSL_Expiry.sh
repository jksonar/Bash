#!/bin/bash

# List of URLs to check
urls=(
    "www.google.com" 
    "www.yahoo.com"
)

# Email recipients
recipients=("s.gaidhani@gmail.com" "j.sonar@gmail.com")

# Function to send email notifications
send_email() {
    local website=$1
    local days_left=$2
    for email in "${recipients[@]}"; do
        echo -e "$website will expire in $days_left days" | mail -s "$website cert will soon expire" "$email"
    done
}

# Loop through each website
for website in "${urls[@]}"; do
    # Create a temporary file for the certificate
    certificate_file=$(mktemp)
    
    # Fetch certificate using OpenSSL
    echo -n | openssl s_client -servername "$website" -connect "$website:443" 2>/dev/null | \
    sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$certificate_file"

    # Check if the certificate file is valid
    if [[ ! -s $certificate_file ]]; then
        echo "Failed to fetch certificate for $website"
        rm -f "$certificate_file"
        continue
    fi

    # Extract the expiry date
    expiry_date=$(openssl x509 -in "$certificate_file" -enddate -noout | sed "s/.*=\(.*\)/\1/")
    
    # Remove temporary file
    rm -f "$certificate_file"
    
    # Convert expiry date to seconds and calculate difference
    expiry_date_s=$(date -d "${expiry_date}" +%s 2>/dev/null)
    now_s=$(date +%s)
    
    # Skip invalid dates
    if [[ -z "$expiry_date_s" ]]; then
        echo "Invalid expiry date for $website"
        continue
    fi

    # Calculate days remaining
    date_diff=$(( (expiry_date_s - now_s) / 86400 ))

    # Notify if the certificate will expire within 20 days
    if [[ "$date_diff" -le 20 ]]; then
        send_email "$website" "$date_diff"
    fi
    
    # Sleep to prevent rate-limiting
    sleep 10
done
