module mood.node;


/// The type of node.
enum NodeType
{
    OpeningTag, /// Indicates that this is an opening tag. i.e. <tag>
    Content,    /// Indicates that this is content. i.e. Contains no html tags in it, and just text only.
    ClosingTag  /// Indicates that this is a closing tag. i.e. </tag>
}

/// Type of tag (if any)
enum TagType
{
    None,   /// Default, used for content
    Tag,    /// Normal HTML tag
    Code,   /// Code tag
    Comment, /// Comment tag
    Insert
}

/// The type of attribute
enum AttributeType
{
    String,     /// String
    Number,     /// Number
    Parameter   /// Parameter i.e. <video autoplay></video>
}

/// Struct that represents the content of a single attribute
struct Attribute
{
    string attribute = "";                      /// The attribute name
    string val = "";                            /// The attribute value
    AttributeType type = AttributeType.String;  /// The attribute type
}

/// Struct that represents a single node
struct Node
{
    NodeType        nodeType = NodeType.Content;        /// The type of node
    TagType         tagType = TagType.None;             /// The type of tag (None if not tag)
    Attribute[]     attributes = cast(Attribute[])[];   /// Array of attributes that the tag has (empty if not tag)
    string          content = "";                       /// Content in the Node. The tag name if a tag, and the content if it is TagType.content
    string          original = "";                      /// Contains original content of the node. Helpful for quickly reconstructing the page after parsing.
}
