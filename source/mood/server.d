module mood.server;

import mood.compiler;
import std.stdio;



string serve(Document doc)
{
    string output;
    foreach(dn; doc.nodes)
    {
        if (dn.code)
        {
            dn.fn(output);
        }
        else
            output ~= dn.content;
    }
    return output;
}

