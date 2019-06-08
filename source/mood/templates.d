module mood.templates;

import std.array: byPair;

/**
 * Generate templates.
 *
 * Used to generate more than a hundred templates used to more easily generate html in webpages.
 *
 * Params:
 *  tags = Array of tags that will be used to generate templates.
 * Returns: Source code of all of the generated templates that will be mixin'd.
*/
private string generateTemplates(string[] tags)()
{
    string code;
    static foreach(tag; tags)
    {
        // default
        code ~= `string ` ~ tag ~ `(string content, string attributes = "") { return "<` ~ tag ~ ` " ~ attributes ~ ">" ~ content ~ "</` ~ tag ~ `>"; }` ~ "\n";
        code ~= `string ` ~ tag ~ `(string content, string[string] attributes) 
        {
            string code = "<` ~ tag ~ `";
            foreach(key, val; attributes.byPair) 
            {
                if (val == "")
                    code ~= " " ~ key;
                else
                {
                    code ~= " " ~ key ~ "=" ~ val;
                }
            }
            code ~= ">" ~ content ~ "</` ~ tag ~ `>";
            return code;
        }` ~ "\n";
    }
    return code;
}

mixin(generateTemplates!([
"a",
"abbr",
"acronym",
"address",
"applet",
"area",
"article",
"aside",
"audio",
"b",
"base",
"basefont",
"Specifies",
"bdi",
"bdo",
"big",
"blockquote",
"body",
"br",
"button",
"canvas",
"caption",
"center",
"cite",
"code",
"col",
"colgroup",
"data",
"datalist",
"dd",
"del",
"details",
"dfn",
"dialog",
"dir",
"div",
"dl",
"dt",
"em",
"embed",
"fieldset",
"figcaption",
"figure",
"font",
"footer",
"form",
"frame",
"frameset",
"h1",
"head",
"header",
"hr",
"html",
"i",
"iframe",
"img",
"input",
"ins",
"kbd",
"label",
"legend",
"li",
"link",
"map",
"mark",
"meta",
"meter",
"nav",
"noframes",
"noscript",
"ol",
"optgroup",
"option",
"output",
"p",
"param",
"picture",
"pre",
"progress",
"q",
"rp",
"rt",
"ruby",
"s",
"samp",
"script",
"section",
"select",
"small",
"source",
"span",
"strike",
"strong",
"style",
"sub",
"summary",
"sup",
"svg",
"table",
"tbody",
"td",
"textarea",
"tfoot",
"th",
"thead",
"time",
"title",
"tr",
"track",
"tt",
"u",
"ul",
"var",
"video",
"wbr"
])());
