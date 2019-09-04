module mood.compiler;

import std.stdio;
import std.string;
import std.conv;

import mood.node;
import mood.parser;

import std.traits: fullyQualifiedName, isBuiltinType, isAssociativeArray, isPointer, PointerTarget, TemplateArgsOf,
                    TemplateOf, isArray;

import std.range.primitives: ElementType;

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
    // resolve imports for params
    
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
    // import blog.post: BlogPost, Comment; // works
    // pragma(msg, getImportStatements!__params);

    // mixin(getImportStatements!__params);

    mixin(getImportList!__params);

    return mixin(createProgram!(__nodes, __params));
}

private string getImportStatementFromFQN(string fqn)
{
	// remove the junk from the fqn
	uint idx = cast(uint)fqn.indexOf('(');
	uint idx2 = cast(uint)fqn.indexOf('.');

	if (idx != -1 && idx2 != -1 && idx < idx2)
		fqn = fqn[idx+1..$];

	// idx = idx == -1 ? 0u : idx;
	// fqn = fqn[idx+1..$];

	char[] delimiters = [')', '(', '!', '[', ']'];


	idx = cast(uint)fqn.length;
	foreach(d; delimiters)
	{
		auto i = fqn.indexOf(d);
		if (i != -1 && i < idx)
			idx = cast(uint)i;
	}

	fqn = fqn[0..idx];
	idx = cast(uint)fqn.lastIndexOf('.');
	return "import " ~ fqn[0..idx] ~ " : " ~ fqn[idx+1..$] ~ ";";
}


private string[] getFQNSFromSymbol(T)()
{
	static if (is(T == void) == true)
		return [];
	else
	{
		// branching types
		static if (isAssociativeArray!T == true) // associative array (hash map)
		{
			return getFQNSFromSymbol!(KeyType!T) ~ getFQNSFromSymbol!(ValueType!T);
		}
		else static if (!is(TemplateOf!T == void))
		{
			string[] fqns = [ fullyQualifiedName!T ];
			static foreach(T; TemplateArgsOf!T)
			{
				fqns ~= getFQNSFromSymbol!T;
			}
			return fqns;
		}
		// non-branching types
		else static if (isPointer!T == false && isArray!T == false && isBuiltinType!T == false) // raw type
			return [ fullyQualifiedName!T ];
		else static if (isPointer!T == true && isBuiltinType!T == false) // pointer type
			return getFQNSFromSymbol!(PointerTarget!T);
		else
			return getFQNSFromSymbol!(ElementType!T); // range type, so return the next lower type
	}
}

string getImportList(params...)()
{
	string buffer;
	string[] fqns;
	static foreach(param; params)
	{
		fqns = getFQNSFromSymbol!(typeof(param));
		foreach(fqn; fqns)
		{
			buffer ~= getImportStatementFromFQN(fqn) ~ "\n";
		}
	}
	return buffer;
}
