#!/bin/bash

# Define the range of URLs to download
start=9
end=4483

# Function to download a single webpage and its associated files
download_page() {
  # Extract the index from the argument (e.g., 123 from "offline_copy/123")
  index=$(basename "$1")

  # Create offline copy directory for this page
  mkdir -p "$1"

  # Download webpage
  curl -m 3 "https://lspimg.com/archives/$index.html" --output "$1/index.html"

  # Extract image URLs from webpage and download images
  counter=0
  grep -oP 'href="\K[^"]+\.webp(?=")' "$1/index.html" | while read -r url; do
    # Extract filename from URL and remove query string if present
    filename=$(basename "$url" | cut -d'?' -f1)
    # Use a counter to generate short, unique filenames
    counter=$((counter+1))
    shortname="img$counter.webp"
    # Download image
    if curl -sS -m 3 "$url" --output "$1/$shortname"; then
      # Replace image URLs in HTML with the new short filename
      sed -i "s|$url|$shortname|g" "$1/index.html"
    else
      echo "Error downloading image: $url"
    fi
  done

  # Download CSS, JS, and other files
  grep -oP 'src="\K[^"]+\.(css|js|webmanifest|ico|svg|png|jpg)(\?\d+)?(?=")|(?<=href=")\K[^"]+\.(css|js)(\?\d+)?(?=")' "$1/index.html" | while read -r url; do
    # Extract filename from URL and remove query string if present
    filename=$(basename "$url" | cut -d'?' -f1)
    # Download file
    if curl -sS -m 3 "https://lspimg.com$url" --output "$1/$filename"; then
      # Replace URLs in HTML with the new local filename
      if [[ "$filename" == *.js ]]; then
        sed -i "s|$url|./$filename|g" "$1/index.html"
      else
        sed -i "s|$url|$filename|g" "$1/index.html"
      fi
    else
      echo "Error downloading file: $url"
    fi
  done

  # Replace hardcoded URLs in HTML with local filenames
  sed -i 's|/usr/themes/mdphoto/style.css?20220120|./style.css|g' "$1/index.html"
  sed -i 's|/usr/themes/mdphoto/css/mdui.css?20220120|./mdui.css|g' "$1/index.html"
  sed -i 's|/usr/themes/mdphoto/css/fancybox.css?2022|./fancybox.css|g' "$1/index.html"
  sed -i 's|/usr/themes/mdphoto/js/main.js?20220120|./main.js|g' "$1/index.html"
}

# Export the function so that it can be called by parallel
export -f download_page

# Loop through the range of URLs and download them in parallel
seq "$start" "$end" | parallel -j4 "download_page offline_copy/{}"
