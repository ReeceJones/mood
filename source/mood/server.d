module mood.server;

import mood.compiler;
import std.stdio;
import vibe.http.server: HTTPServerResponse, HTTPServerRequest, HTTPServerRequestDelegateS;




string serve(Document doc, HTTPServerRequest req, HTTPServerResponse res)
{
    // resulting webpage in string representation
    string output;
    // array containing raw output data from entrypoint call
    string[] programOutput;
    // call the page entrypoint
    doc.entrypoint(programOutput, req, res);
    // writeln(programOutput);
    foreach(dn; doc.nodes)
    {
        // if its a code section, collect output, and insert into webpage
        if (dn.code)
        {
            output ~= programOutput[0];
            programOutput = programOutput[1..$];
        }
        else
            output ~= dn.content;
    }
    return output;
}

