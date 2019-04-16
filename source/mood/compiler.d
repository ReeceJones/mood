module mood.compiler;

import std.stdio;
import std.string;
import std.conv;

import mood.node;
import mood.parser;

import vibe.http.server: HTTPServerRequest, HTTPServerResponse;

// works, but do not trust
immutable bool shrink = false;

/**
 * Struct that represents a single node in a document. 
 *   
 * DocumentNode is used to compress the number of overall nodes that have to be processed on page load. Currently the comment field is unused, though it may be used in the future.
*/
struct DocumentNode
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
    void function(ref string[] outputStream, HTTPServerRequest req, HTTPServerResponse res) entrypoint; /// Entrypoint function for the page. Called on page load.
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
 * Creates the program source for a webpage.
 *
 * Creates the source code for a webpage by taking in all the nodes of the webpage and determining if its a code section or not.
 *
 * Params:
 *  nodes = The nodes of the webpage.
 * Returns: Source code of the program that is mixin'd
*/
string createProgram(Node[] nodes)()
{
    string code = "(ref string[] outputStream, HTTPServerRequest req, HTTPServerResponse res){ outputStream = [\"\"];\n" ~ outputCodeStub;
    foreach(node; nodes)
        if (node.tagType == TagType.Code)
            code ~= node.content ~ "\n outputStream ~= \"\";\n";
    code ~= "\n}";
    return code;
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

/**
 * Compiles a set of nodes into a Document.
 *
 * Takes a set of parsed, and linked nodes, then turns it into an optimized webpage by creating the entrypoint function, of the app, and shortening the normal html content into as few nodes as possible.
 *
 * Params:
 *  __nodes = The webpage nodes.
 * Returns: Compiled Document that represents the webpage.
*/
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

/**
 * Compiles a file into a Document.
 *
 * Takes a file that contains all the code for the webpage, then turns it into an optimized webpage by creating the entrypoint function, of the app, and shortening the normal html content into as few nodes as possible.
 *
 * Params:
 *  file = The file to laod.
 * Returns: Compiled Document that represents the webpage.
*/
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
