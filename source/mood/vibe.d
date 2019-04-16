module mood.vibe;

import vibe.http.server: HTTPServerResponse, HTTPServerRequest, HTTPServerRequestDelegateS;

import mood.compiler;
import mood.server;

/**
 * Render a mood file.
 *
 * Used similarly to staticTemplate in vibe.d. Simply use the router, and then pass this function. It will automatically compile the document, and then serve it
 * 
 * Params:
 *  file = The file to serve.
 * Returns: HTTPServerRequestDelegateS
*/
@property HTTPServerRequestDelegateS moodRender(string file)()
{
    // compile our document
    static doc = compile!(file);
    // serve our document
    return cast(HTTPServerRequestDelegateS)(scope HTTPServerRequest req, scope HTTPServerResponse res) {
        res.writeBody(doc.serve(req, res), "text/html; charset=utf-8");
    };
}
