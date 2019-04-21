module mood.vibe;

import vibe.http.server: HTTPServerResponse, HTTPServerRequest, HTTPServerRequestDelegateS;

import mood.compiler;
import mood.server;
import mood.parser;
import mood.hook;

/**
 * Render a mood file.
 *
 * Used similarly to staticTemplate in vibe.d. Simply use the router, and then pass this function. It will automatically compile the document, and then serve it
 * 
 * Params:
 *  file = The file to serve.
 * Returns: HTTPServerRequestDelegateS
*/
@property HTTPServerRequestDelegateS moodRender(string file, params...)()
{
    pragma(msg, "Compiling " ~ file ~ "...");

    static foreach(i, p; params)
    {
        static if (__traits(identifier, params[i]) == "outputStream" || __traits(identifier, params[i]) == "req" || __traits(identifier, params[i]) == "res")
            static assert(0, "Compilation error in file " ~ file ~ ": parameter name " ~ __traits(identifier, params[i]) ~ " uses a reserved name. Please choose a different parameter name.");
    }

    // parse the HTML document into something the parser can read
	enum tokens = tokenizeDHTML(import(file));
    // parse the tokens into nodes that the compile can read
    enum nodes = parseDHTML(tokens);
    // resolve includes
    enum linkedNodes = link!(nodes)();
    // create our program
    enum program = compileProgram!(linkedNodes, params);
    // compile into optimized document
    enum doc = compile!(linkedNodes);


    // serve our document
    return cast(HTTPServerRequestDelegateS)(scope HTTPServerRequest req, scope HTTPServerResponse res) {
        moodCallHooks(req, res);
        string[] output;
        program(output, req, res, params);
        string document = doc.serve(output);
        res.writeBody(document, "text/html; charset=utf-8");
    };
}
