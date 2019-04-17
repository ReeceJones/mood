module mood.vibe;

import vibe.http.server: HTTPServerResponse, HTTPServerRequest, HTTPServerRequestDelegateS;

import mood.compiler;
import mood.server;
import mood.parser;

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
        string[] output;
        program(output, req, res, params);
        res.writeBody(doc.serve(output), "text/html; charset=utf-8");
    };
}
