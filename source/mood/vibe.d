module mood.vibe;

import vibe.http.server: HTTPServerResponse, HTTPServerRequest, HTTPServerRequestDelegateS;

import mood.compiler;
import mood.server;

@property HTTPServerRequestDelegateS moodRender(string file)()
{
    static Document doc = compile!(file);
    return cast(HTTPServerRequestDelegateS)(scope HTTPServerRequest req, scope HTTPServerResponse res) {
        res.writeBody(doc.serve, "text/html; charset=utf-8");
    };
}
