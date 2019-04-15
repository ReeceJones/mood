module mood.node;

enum NodeType
{
    OpeningTag,
    Content,
    ClosingTag
}

enum TagType
{
    None,   /// Default, used for non-tags
    Tag,    /// Normal HTML tag
    Code,   /// Code tag
    Comment /// Comment tag
}

enum AttributeType
{
    String,
    Number,
    Parameter
}

struct Attribute
{
    string attribute = "";
    string val = "";
    AttributeType type = AttributeType.String;
}

struct Node
{
    NodeType        nodeType = NodeType.Content;    /// The type of node
    TagType         tagType = TagType.None;         /// The type of tag (None if not tag)
    Attribute[]     attributes = cast(Attribute[])[];                /// Array of attributes that the tag has (empty if not tag)
    string          content = "";                   /// Content in the Node. The tag name if a tag, and the content if it is TagType.content
    string          original = "";
}
