import std.stdio;

import mood.node;
import mood.parser;
import mood.compiler;
import mood.server;

unittest
{
    enum testHTML = `<?D
    import mood.templates;
    import std.conv: text;

    output("<ul>");
    for (int i = 1; i <= 5; i++)
    {
        output("<li>ok</li>");
    }
    output("</ul>");
/?>`;
    enum tokens = tokenizeDHTML(testHTML);
    static foreach(tok; tokens)
    {
        pragma(msg, "-----BEGIN TOKEN-----");
        pragma(msg, tok);
        pragma(msg, "-----END TOKEN-----");
    }
    enum nodes = parseDHTML(tokens);
    static foreach(node; nodes)
    {
        pragma(msg, "-----BEGIN NODE-----");
        pragma(msg, node);
        pragma(msg, "-----END NODE-----");
    }
}
