#!/bin/bash

url="$1"
counter="$2"
i="$3"
shortname="img$counter.webp"

echo "Download $url"
if curl -sS -m 3 -v "$url" --output "offline_copy/$i/$shortname"; then
  # Replace image URLs in HTML with the new short filename
  sed -i "s|$url|$shortname|g" "offline_copy/$i/index.html"
else
  echo "Error downloading image: $url"
fi
