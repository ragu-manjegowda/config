#!/bin/bash

###############################################################################
##
## Author       : Ragu Manjegowda
## Github       : @ragu-manjegowda
##
###############################################################################


###############################################################################
### Navigate to the wiki directory
cd ~/wiki/ || { echo 'Wiki not found' && exit; }

echo "Linking modified markdown files in ~/wiki/ to HTML"


###############################################################################
### Convert all markdown files to HTML
mkdir -p html_output/css
mkdir -p html_output/highlight


### Copy Style
css_dir=html_output/css
hl_dir=html_output/highlight

# Define paths to the current and previous theme files
previous_theme_file="html_output/.last_run_theme"

# Check if .last_run exists and read the previous theme
if [[ -f "$previous_theme_file" ]]; then
    previous_theme=$(cat "$previous_theme_file")
else
    previous_theme="N/A"
fi

# Get the current theme (you may want to change this if the format is different)
current_theme="solarized-light"

# Check if themes are different
if [[ "$previous_theme" != "$current_theme" ]]; then
    echo "==================================================================="
    echo "Themes have been updated"
    echo "Current wiki theme: $previous_theme"
    echo "To be updated wiki theme: $current_theme"
    echo "==================================================================="

    read -r -p "Themes are different. Do you want to regenerate? (y/N): " choice
    choice=${choice:-n}  # Default to 'y' if no input is provided
    if [[ "$choice" == "y" ]]; then
        echo "Reprocessing all files..."

        cp "${HOME}/.config/misc/wiki/css/solarized-light.css" "${css_dir}/solarized.css"
        cp "${HOME}/.config/misc/wiki/highlight/solarized-light.theme" "${hl_dir}/solarized.theme"
        cp "${HOME}/.config/misc/wiki/assets/favicon-light.ico" html_output/favicon.ico
        cp "${HOME}/.config/misc/wiki/lua-filters/filters.lua" html_output/filters.lua

        # Touch .last_run with the reference time in the past to reprocess all files
        # Note: ideally we can update just the html files but trying to keep it simple
        touch -t 197001010000 html_output/.last_run

        # Save the current theme as the previous theme for the next run
        echo "$current_theme" > "$previous_theme_file"
    else
        echo "Skipping regeneration."
    fi
fi


### Check if the .last_run file exists
if [ ! -f html_output/.last_run ]; then
    # If it doesn't exist, create a reference time in the past to ensure all files are considered
    touch -t 197001010000 html_output/.last_run
fi

### Iterate over all modified files in the wiki directory since last run
### excluding html_output directory
find . -path ./html_output -prune -o -type f -newer html_output/.last_run -print | while read -r file; do

    echo "Converting $file"

    # Create the output directory
    output_dir="html_output/$(dirname "$file" | cut -c 3-)"  # Remove leading "./" from path
    mkdir -p "$output_dir"

    # Check the file extension
    if [[ "$file" == *.md ]]; then
        # Extract the first H1 from the markdown file to use as the title
        # Get the first line that starts with # and remove the #
        title=$(grep -m 1 '^# ' "$file" | sed 's/^# //')

        # Fallback title if no H1 is found
        if [ -z "$title" ]; then
            title="Default Title"
        fi

        # Convert to HTML with Pandoc, generating a fresh TOC
        pandoc --from=gfm --to=html5 --standalone --embed-resources "$file" \
            --output="$output_dir/$(basename "${file%.md}.html")" \
            --lua-filter=html_output/filters.lua --metadata=base_path:/ \
            --syntax-highlighting="${hl_dir}/solarized.theme" \
            --css="${css_dir}/solarized.css" --metadata pagetitle="$title"
    else
        # Copy non-Markdown files to the output directory
        cp "$file" "$output_dir/"
    fi
done

### Update the last run timestamp
touch html_output/.last_run

###############################################################################
### Start the server
cd html_output || { echo 'HTML output not found' && exit; }

echo "Starting server on port 8000"
python3 -m http.server 8000
