module mood.server;

import mood.compiler;
import std.stdio;
import vibe.http.server: HTTPServerResponse, HTTPServerRequest, HTTPServerRequestDelegateS;

/**
 * Serve a Document.
 *
 * Called when a webpage is requested. When called, this executes the program first, before rendering out the page. After program executing the page is reconstructed using the output of the program execution.
 *
 * Params:
 *  doc = The Document to serve.
 *  req = vibe.d HTTPServerRequest that contains information about the requested page.
 *  res = vibe.d HTTPServerResponse that contains information about the resulting page.
 * Returns: String representation of the reconstructed webpage.
*/
string serve(Document doc, string[] programOutput)
{
    // // resulting webpage in string representation
    string output;
    // // array containing raw output data from entrypoint call
    // string[] programOutput;
    // // call the page entrypoint
    // fn(programOutput, req, res);
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

