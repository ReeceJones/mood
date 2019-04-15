module mood.parser;

import std.stdio;
import std.string;
import mood.node;

int countOccurances(string s, string match, string exclude)
{
    int count;
    foreach(i, c; match)
    {
        foreach(z; s)
        {
            if (c == z && (i == 0 || match[i-1..i+1] != exclude))
                count++;
        }
    }
    return count;
}

string[] tokenizeDHTML(string dhtml)
{
    string[] tokens = [""];
    bool inCode = false;
    foreach(i, c; dhtml)
    {
        if (c == '>')
        {
            if (inCode)
            {
                // check to make sure we are not parsing the D-code
                // int strDelimiters = countOccurances(tokens[$-1], "\"`'", `\"`);

                if (dhtml[i-2..i+1] == "/?>")// && strDelimiters % 2 == 0)
                {
                    tokens[$-1] ~= c;
                    tokens ~= "";
                    inCode = false;
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
        else if (c == '<' && tokens.length > 1 && !inCode)
        {
            if (dhtml[i..i+3] == "<?D")
            {
                inCode = true;
            }
            
            tokens ~= ("" ~ c);
        }
        else
            tokens[$-1] ~= c;
    }
    return tokens;
}

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
                    //parse netx attribute
                    Attribute attr;
                    long idx1 = workingTag.indexOf(" ");
                    long idx2 = workingTag.indexOf("=");
                    long idx3 = workingTag.indexOf("\"");
                    // writeln(workingTag);
                    // writeln("idx1:\t", idx1,"\tidx2:\t", idx2,"\tidx3:\t", idx3);
                    // parameter value
                    // if (idx1 < idx2 && idx1 != -1)
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
