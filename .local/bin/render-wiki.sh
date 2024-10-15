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
### Create a lua script to convert markdown links to HTML
lua_script=$(cat <<'EOF'
function Link(el)
    if el.target:match("%.md") then
        -- Make links relative to the root
        el.target = "/" .. el.target

        -- Replace .md with .html
        el.target = string.gsub(el.target, "%.md$", ".html")
    end

    return el
end
EOF
)


###############################################################################
### Convert all markdown files to HTML
mkdir -p html_output/css
mkdir -p html_output/highlight

echo "$lua_script" > html_output/links-to-html.lua


### Copy Style
css_dir=html_output/css
hl_dir=html_output/highlight

# Check if the script is newer than .last_run
if [[ "$0" -nt html_output/.last_run ]]; then
    cp "${HOME}/.config/misc/wiki/css/solarized-dark.css" "${css_dir}/solarized.css"
    cp "${HOME}/.config/misc/wiki/highlight/solarized-dark.theme" "${hl_dir}/solarized.theme"
    cp "${HOME}/.config/misc/wiki/assets/favicon-dark.ico" html_output/favicon.ico

    echo "==================================================================="
    echo "Themes have been updated, reprocessing all files..."
    echo "==================================================================="

    # Touch .last_run with the reference time in the past to reprocess all files
    touch -t 197001010000 html_output/.last_run
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
            --lua-filter=html_output/links-to-html.lua --metadata=base_path:/ \
            --highlight-style="${hl_dir}/solarized.theme" \
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
