-------------------------------------------------------------------------------
--
-- Author       : Ragu Manjegowda
-- Github       : @ragu-manjegowda
--
-------------------------------------------------------------------------------


-- Define a function to convert markdown links to appropriate HTML links
function Link(el)
    if el.target:match("%.md") then
        -- Make links relative to the root
        el.target = "/" .. el.target

        -- Replace .md with .html
        el.target = string.gsub(el.target, "%.md$", ".html")
    end

    return el
end

-------------------------------------------------------------------------------
-- This function adds support for Github Flavored Markdown's "Note", "Warning",
-- "Tip", "Caution", and "Important" markers.
-- https://github.com/orgs/community/discussions/16925
--
-------------------------------------------------------------------------------

-- Pandoc somehow does not add blockquote for [!Note], [!Tip] and [!Important]
-- Fix it and add icon to Note and then convert to BlockQuote
function Div(el)
    -- Check if the Div has the class "note"
    if el.classes:includes("note") or el.classes:includes("tip") or
        el.classes:includes("important") then
        -- Check if the Div has the class "title"
        -- [Div ("",["title"],[]) [Para [Str "Note"]],Para [Str "..."]]

        -- Iterate through the content of the outer Div
        for i, innerBlock in ipairs(el.content) do
            -- Check if the inner block is a Div with class "title"
            if innerBlock.t == "Div" and innerBlock.classes:includes("title") then
                -- Iterate through the content of the inner "title" Div
                for _, block in ipairs(innerBlock.content) do
                    -- Check if the block is a Para containing the text "Note"
                    if block.t == "Para" and
                        #block.content == 1 and
                        block.content[1].t == "Str" then
                        local text = ""
                        local assignModified = false

                        if block.content[1].text == "Note" then
                            -- Prepend the icon to the "Note" text
                            text = pandoc.Span(
                                pandoc.Str("  Note"),
                                { class = "note-icon" })
                            assignModified = true
                        end

                        if block.content[1].text == "Tip" then
                            -- Prepend the icon to the "Tip" text
                            text = pandoc.Span(
                                pandoc.Str("  Tip"),
                                { class = "tip-icon" })
                            assignModified = true
                        end

                        if block.content[1].text == "Important" then
                            -- Prepend the icon to the "Tip" text
                            text = pandoc.Span(
                                pandoc.Str("󰨄  Important"),
                                { class = "important-icon" })
                            assignModified = true
                        end

                        if assignModified then
                            block.content[1] = text
                            -- Assign the modified block to the Div
                            innerBlock.content[i] = block
                        end
                    end
                end
            end

            -- Assign the modified content to the Div
            el.content[i] = innerBlock
        end

        -- Extract the content from the Div and convert it to a BlockQuote
        local blockquote = pandoc.BlockQuote(el.content)

        -- Return the transformed BlockQuote
        return blockquote
    end

    -- Return the Div unchanged if it doesn't match
    return el
end

-- Add icon to [!Info], [!Check], [!Help], [!Reference], [!Resource]
function BlockQuote(el)
    for _, block in ipairs(el.content) do
        -- Check if the block is a Para (paragraph)
        if block.t == "Para" then
            local firstElem = block.content[1]

            local addLineBreak = false
            local text = ""

            -- Check if the first element is a Str (string) that matches "[!Info]"
            if firstElem and firstElem.t == "Str" then
                if firstElem.text == "[!Info]" then
                    -- Replace the text with "Info" and prepend an icon
                    text = pandoc.Span(
                        pandoc.Str("  Info"),
                        { class = "info-icon" })

                    addLineBreak = true
                end

                if firstElem.text == "[!Check]" then
                    -- Replace the text with "Check" and prepend an icon
                    text = pandoc.Span(
                        pandoc.Str("  Check"),
                        { class = "check-icon" })

                    addLineBreak = true
                end

                if firstElem.text == "[!Help]" then
                    -- Replace the text with "Help" and prepend an icon
                    text = pandoc.Span(
                        pandoc.Str("  Help"),
                        { class = "help-icon" })

                    addLineBreak = true
                end

                if firstElem.text == "[!Reference]" or firstElem.text == "[!References]" then
                    -- Replace the text with "Reference" and prepend an icon
                    text = pandoc.Span(
                        pandoc.Str("  Reference"),
                        { class = "reference-icon" })

                    addLineBreak = true
                end

                if firstElem.text == "[!Resources]" or firstElem.text == "[!Resources]" then
                    -- Replace the text with "Resource" and prepend an icon
                    text = pandoc.Span(
                        pandoc.Str("  Resources"),
                        { class = "resources-icon" })

                    addLineBreak = true
                end

                if addLineBreak then
                    block.content[1] = text

                    -- Insert a line break after "Tag"
                    table.insert(block.content, 2, pandoc.LineBreak())

                    -- Remove any extra space that may follow "[!Tag]"
                    if block.content[3] and block.content[3].t == "Space" then
                        table.remove(block.content, 3)
                    end
                end
            end
        end
    end

    -- Return the BlockQuote
    return el
end
