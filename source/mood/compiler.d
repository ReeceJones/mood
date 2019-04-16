module mood.compiler;

import std.stdio;
import std.string;
import std.conv;

import mood.node;
import mood.parser;

import vibe.http.server: HTTPServerRequest, HTTPServerResponse;

// works, but do not trust
immutable bool shrink = false;

struct DocumentNode
{
    bool code = false;      /// True if the section is a code section. Used in the server to determine output ordering.
    bool comment = false;   /// True if the section is a comment. Reserved for potential future use.
    string content = "";    /// The string content of the section.
}

struct Document
{
    DocumentNode[] nodes = [];                                                                          /// The individual document nodes that make a page.
    uint codeSections = 0;                                                                              /// The number of code sections
    void function(ref string[] outputStream, HTTPServerRequest req, HTTPServerResponse res) entrypoint; /// Entrypoint function for the page. Called on page load.
}

immutable string outputCodeStub = `import _stub = std.conv: text;
void output(T...)(T Args)
{
    foreach(arg; Args)
    {
        outputStream[$-1] ~= _stub.text(arg); 
    }
}
`;

string createProgram(Node[] nodes)()
{
    string code = "(ref string[] outputStream, HTTPServerRequest req, HTTPServerResponse res){ outputStream = [\"\"];\n" ~ outputCodeStub;
    foreach(node; nodes)
        if (node.tagType == TagType.Code)
            code ~= node.content ~ "\n outputStream ~= \"\";\n";
    code ~= "\n}";
    return code;
}

private Node[] importAndParse(string file)()
{
    enum tokens = tokenizeDHTML(import(file));
    enum nodes = parseDHTML(tokens);
    return nodes;
}

Node[] link(Node[] nodes)()
{
    Node[] result;
    static foreach(node; nodes)
    {
        static if (node.tagType == TagType.Tag && node.content.length >= 9 && node.content[0..8] == "include:")
            result ~= link!(importAndParse!(node.content[8..$-1])());
        else
            result ~= node;
    }
    return result;
}

Document compile(Node[] __nodes)()
{
    Document __doc; // resulting document
    __doc.nodes ~= DocumentNode.init; // start off with a blank document node
    static foreach(__node; __nodes)
    {
        // continue not work well in static foreach
        static if (shrink && __node.nodeType == NodeType.Content && __node.content.strip.length == 0) {}
        else
        {
            // add a new section if we hit a code section
            static if (__node.tagType == TagType.Code)
            {
                __doc.codeSections++;
                __doc.nodes ~= DocumentNode(true, false, __node.content);
                __doc.nodes ~= DocumentNode.init;
            }
            else
                __doc.nodes[$-1].content ~= __node.original; // otherwise add the string contents
        }
    }

    // create the page's program
    enum prog = createProgram!__nodes;
    // pragma(msg, prog);
    __doc.entrypoint = mixin(prog);
    return __doc;
}

Document compile(string file)()
{
    pragma(msg, "Compiling " ~ file ~ "...");
    // parse the HTML document into something the parser can read
	enum tokens = tokenizeDHTML(import(file));
    // parse the tokens into nodes that the compile can read
    enum nodes = parseDHTML(tokens);
    // resolve includes
    enum linkedNodes = link!(nodes)();
    // compile into optimized document
    return compile!(linkedNodes);
}
