function quarto_block(x)
    s = """

    :::{.callout-note appearance="simple"}

    # doc

    $x

    :::

    """

    s = replace(string(s), "\n#" => "\n###")

    return Markdown.parse(s)
end

macro qdoc(f)
    quote
        quarto_block(@doc $f)
    end
end