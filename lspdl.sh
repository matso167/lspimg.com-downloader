#!/bin/bash

# Define the range of URLs to download
start=9
end=4483

# Loop through the range of URLs
for (( i=start; i<=end; i++ )); do
  # Create offline copy directory for this page
  mkdir -p offline_copy/$i

  # Download webpage
  curl -m 3 "https://lspimg.com/archives/$i.html" --output "offline_copy/$i/index.html"

  # Extract image URLs from webpage and download images
  counter=0
  grep -oP 'href="\K[^"]+\.webp(?=")' "offline_copy/$i/index.html" | while read -r url; do
    # Extract filename from URL and remove query string if present
    filename=$(basename "$url" | cut -d'?' -f1)
    # Use a counter to generate short, unique filenames
    counter=$((counter+1))
    shortname="img$counter.webp"
    # Download image
    if curl -sS -m 3 "$url" --output "offline_copy/$i/$shortname"; then
      # Replace image URLs in HTML with the new short filename
      sed -i "s|$url|$shortname|g" "offline_copy/$i/index.html"
    else
      echo "Error downloading image: $url"
    fi
  done

  # Download CSS, JS, and other files
  grep -oP 'src="\K[^"]+\.(css|js|webmanifest|ico|svg|png|jpg)(\?\d+)?(?=")|(?<=href=")\K[^"]+\.(css|js)(\?\d+)?(?=")' "offline_copy/$i/index.html" | while read -r url; do
    # Extract filename from URL and remove query string if present
    filename=$(basename "$url" | cut -d'?' -f1)
    # Download file
    if curl -sS -m 3 "https://lspimg.com$url" --output "offline_copy/$i/$filename"; then
      # Replace URLs in HTML with the new local filename
      if [[ "$filename" == *.js ]]; then
        sed -i "s|$url|./$filename|g" "offline_copy/$i/index.html"
      else
        sed -i "s|$url|$filename|g" "offline_copy/$i/index.html"
      fi
    else
      echo "Error downloading file: $url"
    fi
  done

  sed -i 's|/usr/themes/mdphoto/style.css?20220120|./style.css|g' "offline_copy/$i/index.html"
  sed -i 's|/usr/themes/mdphoto/css/mdui.css?20220120|./mdui.css|g' "offline_copy/$i/index.html"
  sed -i 's|/usr/themes/mdphoto/css/fancybox.css?2022|./fancybox.css|g' "offline_copy/$i/index.html"
  sed -i 's|/usr/themes/mdphoto/js/main.js?20220120|./main.js|g' "offline_copy/$i/index.html"
done
