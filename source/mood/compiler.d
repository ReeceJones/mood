module mood.compiler;

import std.stdio;
import std.string;
import std.conv;

import mood.node;
import mood.parser;

import vibe.http.server: HTTPServerRequest, HTTPServerResponse;

// works, but do not trust. Look more into later.
private immutable bool shrink = false;

/**
 * Struct that represents a single node in a document. 
 *   
 * DocumentNode is used to compress the number of overall nodes that have to be processed on page load. Currently the comment field is unused, though it may be used in the future.
*/
private struct DocumentNode
{
    bool code = false;      /// True if the section is a code section. Used in the server to determine output ordering.
    bool comment = false;   /// True if the section is a comment. Reserved for potential future use.
    string content = "";    /// The string content of the section.
}


/**
 * A struct that represents a compiled webpage
 *
 * Returned by compile, and contains an entrypoint function to run all of the code that is on the webpage. Currently codeSections is unused, but in the future will be used for error checking.
*/
struct Document
{
    DocumentNode[] nodes = [];                                                                          /// The individual document nodes that make a page.
    uint codeSections = 0;                                                                              /// The number of code sections
}

/**
 * Params:
 *  file = The file to import and parse
 * Returns: Parsed file
*/
private Node[] importAndParse(string file)()
{
    enum tokens = tokenizeDHTML(import(file));
    enum nodes = parseDHTML(tokens);
    return nodes;
}

/**
 * Resolve any includes that are in a parsed file.
 *
 * iterates over all of the parsed nodes and if there is a node that is an include tag i.e. <include:file.html/>, then it will load the file, and try and insert it into the webpage.
 * Note: This will fail if two or more includes rely on each other. If you get an error along the lines of too many levels of CTFE recursion, then you may have one file that includes itself.
 * 
 * Params:
 *  nodes = The nodes of the current webpage that are to be parsed over.
 * Returns: The resulting webpage with all includes inserted into it.
*/
Node[] link(const Node[] nodes)()
{
    Node[] result;
    static foreach(node; nodes)
    {
        static if (node.tagType == TagType.Tag && node.content.length >= 9 && node.content[0..8] == "include:")
        {
            static if (node.content[$-1] != '/')
                static assert(0, "Compilation error: Malformed include statement. Missing \"/\"?");
            result ~= link!(importAndParse!(node.content[8..$-1])());
        }
        else
            result ~= node;
    }
    return result;
}

/**
 * Compiles a set of nodes into a Document.
 *
 * Takes a set of parsed, and linked nodes, then turns it into an optimized webpage by creating the entrypoint function, of the app, and shortening the normal html content into as few nodes as possible.
 *
 * Params:
 *  nodes = The webpage nodes.
 * Returns: Compiled Document that represents the webpage.
*/
Document compile(const Node[] nodes)()
{
    Document doc; // resulting document
    doc.nodes ~= DocumentNode.init; // start off with a blank document node
    static foreach(node; nodes)
    {
        // continue not work well in static foreach
        static if (shrink && node.nodeType == NodeType.Content && node.content.strip.length == 0) {}
        else
        {
            // add a new section if we hit a code section
            static if (node.tagType == TagType.Code)
            {
                doc.codeSections++;
                doc.nodes ~= DocumentNode(true, false, node.content);
                doc.nodes ~= DocumentNode.init;
            }
            else static if (node.tagType == TagType.Insert)
            {
                doc.codeSections++;
                doc.nodes ~= DocumentNode(true, false, node.content);
                doc.nodes ~= DocumentNode.init;
            }
            else
                doc.nodes[$-1].content ~= node.original; // otherwise add the string contents
        }
    }

    return doc;
}


/// A block of code that is inserted into the beginning of every webpage program so that it can have output functionality.
immutable string outputCodeStub = `import _stub = std.conv: text;
void output(T...)(T Args)
{
    foreach(arg; Args)
    {
        outputStream[$-1] ~= _stub.text(arg); 
    }
}
`;

/**
 * Converts template parameters to function parameters.
 *
 * Used to convert template parameters into the function parameters that are passed to the executable function on page load.
 * 
 * Params:
 *  params = The params that are to be converted.
 * Returns: The resulting code from the conversion.
*/
string extendParameters(params...)()
{
    string code = "";
    static foreach(i, p; params)
    {
        code ~= ", " ~ typeof(params[i]).stringof ~ " " ~ __traits(identifier, params[i]);
    }
    return code;
}

/**
 * Creates the program source for a webpage.
 *
 * Creates the source code for a webpage by taking in all the nodes of the webpage and determining if its a code section or not.
 *
 * Params:
 *  nodes = The nodes of the webpage.
 * Returns: Source code of the program that is mixin'd
*/
string createProgram(const Node[] nodes, params...)()
{
    string code = "(ref string[] outputStream, HTTPServerRequest req, HTTPServerResponse res" ~ extendParameters!params ~ "){ outputStream = [\"\"];\n" ~ outputCodeStub;
    foreach(node; nodes)
        if (node.tagType == TagType.Code)
            code ~= node.content ~ "\n outputStream ~= \"\";\n";
        else if (node.tagType == TagType.Insert)
            code ~= "output(" ~ node.content ~ ");\n outputStream ~= \"\";\n";
    code ~= "\n}";
    return code;
}

/**
 * Creates executable program for a webpage
 * 
 * Takes in a set of nodes and parameters and creates the executable function that is used to run code on a webpage
 * 
 * Params:
 *  __nodes = The nodes of the webpage itself
 * __params = the parameters that are passed to the webpage through the render function.
 * Returns: automatically deduced function that is ran on page load.
*/
auto compileProgram(const Node[] __nodes, __params...)()
{
    pragma(msg, createProgram!(__nodes, __params));
    return mixin(createProgram!(__nodes, __params));
}
