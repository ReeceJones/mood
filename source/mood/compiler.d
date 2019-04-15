module mood.compiler;

import std.stdio;
import std.string;
import std.conv;

import mood.node;
import mood.parser;

immutable bool shrink = false;

struct DocumentNode
{
    bool code = false;
    bool comment;
    string content = "";
    void function(ref string) fn;
}

struct Document
{
    DocumentNode[] nodes = [];
}

immutable string outputCodeStub = `import _stub = std.conv: text;
void output(T...)(T Args)
{
    foreach(arg; Args)
    {
        outputStream ~= _stub.text(arg); 
    }
}
`;

Document compile(Node[] __nodes)()
{
    Document __doc;
    __doc.nodes ~= DocumentNode.init;
    // mixin("int yikes = 69;");
    static foreach(__node; __nodes)
    {
        static if (shrink && __node.nodeType == NodeType.Content && __node.content.strip.length == 0)
            continue;
        static if (__node.tagType == TagType.Code)
        {
            // pragma(msg, "(ref string outputStream){" ~ outputCodeStub ~ node.content ~ "\n}");
            __doc.nodes ~= DocumentNode(true, __node.tagType == TagType.Comment, 
                                        "(ref string outputStream){" ~ outputCodeStub ~ __node.content ~ "\n}",
                                        mixin("(ref string outputStream){" ~ outputCodeStub ~ __node.content ~ "\n}"));
            __doc.nodes ~= DocumentNode.init;
        }
        static if (__node.tagType != TagType.Code)
            __doc.nodes[$-1].content ~= __node.original;
    }

    return __doc;
}

Document compile(string file)()
{
    pragma(msg, "Compiling " ~ file ~ "...");
	enum tokens = tokenizeDHTML(import(file));
    enum nodes = parseDHTML(tokens);
    return compile!(nodes);
}
