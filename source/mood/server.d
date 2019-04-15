module mood.server;

import mood.compiler;
import std.stdio;



string serve(Document doc)
{
    string output;
    string[] programOutput;
    doc.fn(programOutput);
    writeln(programOutput);
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

