module mood.parser;

import std.stdio;
import std.string;
import mood.node;

/**
 * Takes raw html data and tokenizes it.
 *
 * Does not completely parse the html, but is used to make parsing much easier, and to seperate it into different parts.
 *
 * Params:
 *  dhtml = The html that is to be tokenized.
 * Returns: Tokenized html in the form of a string array.
*/
string[] tokenizeDHTML(string dhtml)
{
    string[] tokens = [""];
    bool inCode = false;
    string codeType = "";
    foreach(i, c; dhtml)
    {
        if (c == '>')
        {
            if (inCode)
            {
                if (i >= 2 && i + 1 <= dhtml.length && dhtml[i-2..i+1] == "/?>" && codeType == "D")
                {
                    tokens[$-1] ~= c;
                    tokens ~= "";
                    inCode = false;
                    codeType = "";
                }
                else if (i >= 8 && i + 1 <= dhtml.length && dhtml[i-8..i+1] == "</script>" && codeType == "script")
                {
                    tokens[$-1] ~= c;
                    tokens ~= "";
                    inCode = false;
                    codeType = "";
                }
                else if (i >= 7 && i + 1 <= dhtml.length && dhtml[i-7..i+1] == "</style>" && codeType == "style")
                {
                    tokens[$-1] ~= c;
                    tokens ~= "";
                    inCode = false;
                    codeType = "";
                }
                else
                    tokens[$-1] ~= c;
            }
            else
            {
                tokens [$-1] ~= c;
                tokens ~= "";
            }
        }
        else if (c == '<' && tokens.length >= 0 && !inCode)
        {
            if (i + 3 <= dhtml.length && dhtml[i..i+3] == "<?D" && codeType == "")
            {
                inCode = true;
                codeType = "D";
            }
            if (i + 8 <= dhtml.length && dhtml[i..i+8] == "<script>" && codeType == "")
            {
                inCode = true;
                codeType = "script";
            }
            if (i + 7 <= dhtml.length && dhtml[i..i+7] == "<style>" && codeType == "")
            {
                inCode = true;
                codeType = "style";
            }
            
            tokens ~= ("" ~ c);
        }
        else
            tokens[$-1] ~= c;
    }
    return tokens;
}
private string[] removeJunk(string[] data)
{
    import std.string: strip;
    string[] sanitized;
    foreach(tok; data)
    {
        if (tok.strip.length > 0)
            sanitized ~= tok;
    }
    return sanitized;
}

unittest
{
    /* Test 1 */
    writeln("starting parsing test 1");
    string html = 
    `<!DOCTYPE html>
    <html>
        <head>
            <title>hello world</title>
        </head>
        <body>
            <h1>Hello World!</h1>
            <p>lorem ipsum text</p>
        </body>
    </html>`;
    string[] tokens;
    tokens = tokenizeDHTML(html).removeJunk;
    writeln(tokens);
    assert(tokens[0] == "<!DOCTYPE html>");
    assert(tokens[1] == "<html>");
    assert(tokens[2] == "<head>");
    assert(tokens[3] == "<title>");
    assert(tokens[4] == "hello world");
    assert(tokens[5] == "</title>");
    assert(tokens[6] == "</head>");
    assert(tokens[7] == "<body>");
    assert(tokens[8] == "<h1>");
    assert(tokens[9] == "Hello World!");
    assert(tokens[10] == "</h1>");
    assert(tokens[11] == "<p>");
    assert(tokens[12] == "lorem ipsum text");
    assert(tokens[13] == "</p>");
    assert(tokens[14] == "</body>");
    assert(tokens[15] == "</html>");

    /* Test 2 */
    writeln("starting test 2");
    html = 
`<!DOCTYPE html>
<?D
    import std.stdio;
/?>
<html>
    <body>
        <?D
            output("Hello World");
        /?>
    </body>
</html>`;
    tokens = tokenizeDHTML(html).removeJunk;
    writeln(tokens);
    assert(tokens[1] == 
`<?D
    import std.stdio;
/?>`);
    assert(tokens[4] == 
        `<?D
            output("Hello World");
        /?>`);
}

/**
 * Parses tokenized html data.
 *
 * Takes in tokenized html data and outputs a set of nodes that contain information about itself.
 *
 * Params:
 *  tokens = The tokens that are output from tokenizing the html data.
 * Returns: Parsed html nodes.
*/
Node[] parseDHTML(string[] tokens)
{
    Node[] nodes;
    Node current;
    foreach(i, tok; tokens)
    {
        if (tok.length == 0)
            continue;

        if (tok.strip.length >= 4 && tok.strip[0..4] == "<!--")
        {
            current.nodeType = NodeType.OpeningTag;
            current.tagType = TagType.Comment;
            current.original = tok;
            nodes ~= current;
            current = Node.init;
            continue;
        }
        else if (tok.strip.length >= 3 && tok.strip[0..3] == "-->")
        {
            current.nodeType = NodeType.ClosingTag;
            current.tagType = TagType.Comment;
            current.original = tok;
            nodes ~= current;
            current = Node.init;
            continue;
        }

        current.original = tok;
        // first, determine the NodeType
        if (tok.length >= 2 && tok[0..2] == "</")
            current.nodeType = NodeType.ClosingTag;
        else if (tok[0] == '<')
            current.nodeType = NodeType.OpeningTag;
        else
            current.nodeType = NodeType.Content;

        // second, determine the tag type
        if (current.nodeType == NodeType.Content)
            current.tagType = TagType.None;
        else if (tok.length >= 3 && tok[0..3] == "<?D")
            current.tagType = TagType.Code;
        else
            current.tagType = TagType.Tag;
        // next determine the attributes if its a tag
        if (current.nodeType == NodeType.Content)
        {
            current.content = tok;
        }
        else if (current.tagType == TagType.Tag)
        {
            long idx = tok.indexOf("<");
            string workingTag = tok[idx + 1..$-1];
            idx = workingTag.indexOf(" ");
            idx = idx == -1 ? workingTag.length : idx;
            current.content = workingTag[0..idx];
            workingTag = workingTag[idx..$];
            current.attributes = cast(Attribute[])[];
            if (current.nodeType == NodeType.OpeningTag)
            {
                foreach(_zzz; 0..24)
                {
                    workingTag = workingTag.stripLeft;
                    if (workingTag.length == 0)
                        break;
                    //parse next attribute
                    Attribute attr;
                    long idx1 = workingTag.indexOf(" ");
                    long idx2 = workingTag.indexOf("=");
                    long idx3 = workingTag.indexOf("\"");

                    if (idx1 <= idx2 && idx2 + 1 != idx3)
                    {
                        idx1 = idx1 == -1 ? workingTag.length : idx1;
                        attr.attribute = workingTag[0..idx1];
                        attr.type = AttributeType.Parameter;
                        workingTag = workingTag[idx1..$];
                    }
                    else if (idx2 + 1 == idx3) // String value
                    {
                        attr.attribute = workingTag[0..idx2];
                        long idx4 = workingTag.indexOf("\"", idx3+1);
                        idx4 = idx4 == -1 ? workingTag.length : idx4;
                        attr.val = workingTag[idx3+1..idx4];
                        attr.type = AttributeType.String;
                        if (idx4 + 1 < workingTag.length)
                            workingTag = workingTag[idx4+2..$];
                        else
                            workingTag = "";
                    }
                    else if (idx2 > 0)// Number Value
                    {
                        attr.attribute = workingTag[0..idx2];
                        long idx4 = workingTag.indexOf(" ", idx2);
                        idx4 = idx4 == -1 ? workingTag.length : idx4;
                        attr.val = workingTag[idx2+1..idx4];
                        attr.type = AttributeType.Number;
                        if (idx4 != workingTag.length)
                            workingTag = workingTag[idx4+1..$];
                        else
                            workingTag = "";
                    }
                    else if (idx1 == -1)
                        workingTag = "";
                    current.attributes ~= attr;
                }
            }
        }
        else if (current.tagType == TagType.Code)
        {
            current.content = tok[3..$-3];
        }


        nodes ~= current;
        current = Node.init;
    }
    return nodes;
}
