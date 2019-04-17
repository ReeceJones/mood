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
 *  programOutput = The output of the program exeuction that is used to re-construct the webpage.
 * Returns: String representation of the reconstructed webpage.
*/
string serve(Document doc, string[] programOutput)
{
    // resulting webpage in string representation
    string output;
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

