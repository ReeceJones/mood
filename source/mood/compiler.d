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
    bool code = false;
    bool comment;
    string content = "";
}

struct Document
{
    DocumentNode[] nodes = [];
    uint codeSections = 0;
    void function(ref string[] outputStream, HTTPServerRequest req, HTTPServerResponse res) fn;
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
    code ~= "}";
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
        {
            result ~= link!(importAndParse!(node.content[8..$-1])());
        }
        else
        {
            result ~= node;
        }
    }
    return result;
}

Document compile(Node[] __nodes)()
{
    Document __doc;
    __doc.nodes ~= DocumentNode.init;
    // string code = "(ref string outputStream){";
    static foreach(__node; __nodes)
    {
        static if (shrink && __node.nodeType == NodeType.Content && __node.content.strip.length == 0)
        {

        }
        else
        {
            static if (__node.tagType == TagType.Code)
            {
                __doc.codeSections++;
                // pragma(msg, "(ref string outputStream){" ~ outputCodeStub ~ node.content ~ "\n}");
                __doc.nodes ~= DocumentNode(true, __node.tagType == TagType.Comment, 
                                            "(ref string outputStream, HTTPServerRequest req, HTTPServerResponse res){" ~ __node.content ~ "\n}");
                // code ~= __node.content ~ "\n";
                                            // mixin("(ref string outputStream){" ~ outputCodeStub ~ __node.content ~ "\n}"));
                __doc.nodes ~= DocumentNode.init;
            }
            else
                __doc.nodes[$-1].content ~= __node.original;
        }
    }
    // code ~= "}";
    __doc.fn = mixin(createProgram!__nodes);
    return __doc;
}

Document compile(string file)()
{
    pragma(msg, "Compiling " ~ file ~ "...");
	enum tokens = tokenizeDHTML(import(file));
    enum nodes = parseDHTML(tokens);
    enum linkedNodes = link!(nodes)();
    // static foreach(node; nodes)
    // {
    //     pragma(msg, node.content);
    // }
    return compile!(linkedNodes);
}
