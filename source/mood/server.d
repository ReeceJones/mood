module mood.server;

import mood.compiler;
import std.stdio;
import vibe.http.server: HTTPServerResponse, HTTPServerRequest, HTTPServerRequestDelegateS;




string serve(Document doc, HTTPServerRequest req, HTTPServerResponse res)
{
    string output;
    string[] programOutput;
    doc.fn(programOutput, req, res);
    // writeln(programOutput);
    foreach(dn; doc.nodes)
    {
        if (dn.code)
        {
            // dn.fn(output);
            output ~= programOutput[0];
            programOutput = programOutput[1..$];
        }
        else
            output ~= dn.content;
    }
    return output;
}

