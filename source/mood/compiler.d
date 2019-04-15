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
    // void function(ref string) fn;
}

struct Document
{
    DocumentNode[] nodes = [];
    uint codeSections = 0;
    void function(ref string[] outputStream) fn;
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
    string code = "(ref string[] outputStream){ outputStream = [\"\"];\n" ~ outputCodeStub;
    foreach(node; nodes)
        if (node.tagType == TagType.Code)
            code ~= node.content ~ "\n outputStream ~= \"\";\n";
    code ~= "}";
    return code;
}

Document compile(Node[] __nodes)()
{
    Document __doc;
    __doc.nodes ~= DocumentNode.init;
    // string code = "(ref string outputStream){";
    static foreach(__node; __nodes)
    {
        static if (shrink && __node.nodeType == NodeType.Content && __node.content.strip.length == 0)
            continue;
        static if (__node.tagType == TagType.Code)
        {
            __doc.codeSections++;
            // pragma(msg, "(ref string outputStream){" ~ outputCodeStub ~ node.content ~ "\n}");
            __doc.nodes ~= DocumentNode(true, __node.tagType == TagType.Comment, 
                                        "(ref string outputStream){" ~ __node.content ~ "\n}");
            // code ~= __node.content ~ "\n";
                                        // mixin("(ref string outputStream){" ~ outputCodeStub ~ __node.content ~ "\n}"));
            __doc.nodes ~= DocumentNode.init;
        }
        static if (__node.tagType != TagType.Code)
            __doc.nodes[$-1].content ~= __node.original;
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
    return compile!(nodes);
}