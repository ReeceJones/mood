# mood
## What is mood
mood builds on top of the core functionality of vibe.d. Instead of being a new framework, mood replaces the use of diet in favor of a more php-like system.
## Getting Started
1. Create an html file and place whatever code you want into it.
```html
<!DOCTYPE html>
<html>
    <body>
        <?D
            output("hello from mood");
        /?>
    </body>
</html>
```
2. Render our page using `moodRender`.
```D
import vibe.d;
import mood.vibe;

shared static this()
{
	auto router = new URLRouter;
	router.get("/", moodRender!"index.html");
	auto settings = new HTTPServerSettings;
	settings.port = 9001;
	settings.bindAddresses = ["::1", "0.0.0.0"];

	listenHTTP(settings, router);
}
```
## Using mood
You can open and close D-code tags like this:
```
<?D
    ...
/?>
```
Within each html file, one `HTTPServerRequest req` and one `HTTPServerResponse res` are passed as parameters, and available for use.
Each html file also has the function `output(T...)(T args)`, which writes data to the html document, as `echo` would in PHP. You can use this like you would `writeln` in the standard library.
## Includes
The syntax for includes is very simple:
`<include:file.html/>`
Includes in mood insert the contents of the include file into the parent file. This includes all of its code, and its own includes.
## Templates
To use templates, import `mood.templates` in your html file, and run the function that corresponds to the tag.
You can use a template like:
```D
output("Hello World".h1);
output("Hello World".h1); // <h1>Hello World</h1>
output("Hello World".h1(`class="title"`)); // <h1 class="title">Hello World</h1>
output("Hello World".h1([
    `class`: `"title"`
])); // <h1 class="title">Hello World</h1>
```
Note: template, main, and object tags are not supported.
## Future Plans
+ Pass parameters similarly to how you would with diet.
+ Add ability to hook render function.
## Contributing
If you have a suggestion, bug fix, or want a feature added, submit a PR, or an issue. Feedback is appreciated :)
