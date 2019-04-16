# mood
## Introduction
After spending some time with the vanilla vibe.d framework, I started to get a bit tired and annoyed at using the diet files for each web page.
### Why can diet be annoying?
Don't get me wrong, I like diet, and think that it's a very elegant solution for generating dynamic web pages, but there are some things that irk me.

The first thing that really annoys me is just how much overhead I have to write on the server side to setup all of the diet templates correctly. This is because I can't directly include blocks of code right into diet. Well, I can, but it looks awful, and diet even says that it's not meant for more complex logic. So, if I wanted to say, implement an authentification system on top of the vanilla diet/vibe.d combo, and I want to check for authentification on every page, I have to either check for authentification in every single router function, or make my own new "render" function that automatically does it, then use that function for everything else instead of res.render, and the result becomes just a bunch of spaghetti code with routers laying all over the place. The result is a project that becomes increasingly difficult to manage as it grows since so many different minute factors lead to weird design choices.

The second thing that frustrated me was that most of the code had to be done in router functions. This goes hand in hand with the previous complaint, but it really upset me when I had to create a completely new router function for one page that was similar to other router functions, but had one slight change in code, so I had to add a new router function.

The third thing that upset me was the syntax. diet is nice, but its also largely undocumented, and can lead to some frustrating errors.

### My solution
My Solution to the problems listed above was to:
1. Make a PHP-like addition on top of vibe.d so that instead of using diet templates, I can have sub-modules in that contain helper functions.
2. Split the logic between the page and the backend.
3. Use a more html-like syntax.

### What is mood
Well, mood builds on top of the core functionality of vibe.d. Instead of being a new framework outright, mood replaces the need for diet templates in vibe.d mood uses html files with D code baked in, similarly to how PHP is baked into .php files. 

You can open and close D-code tags like this:
```
<?D
    ...
/?>
```
## How does it work
### Architecture
Every html file is treated as a single mini-program. This means you can declare a variable at the top of your html file in one tag, then accesss it at the bottom of your file in another tag. Mood also has support for including other html files. When including a file, the included file is **not** treated as its own executable, and therefore must compile within the parent file that includes it. Includes only copy the contents of the target include file into the parent file.

Within each html file, three variables are exposed to the mini-program:
+ `ref string[] outputStream` - I would not recommend directly modifying this variable. This variable is used to store the program execution result, and match it up with the corresponding tags. **DO NOT** modify the length of outputStream; This may cause the server to crash.
+ `HTTPServerRequest req` - vibe.d's server request. Same as you would get if you used a router function.
+ `HTTPServerResponse res` - vibe.d's server response. Same as you would get if you used a router function.

Within each html file there is also one function:
`output(T...)(T args)` - Writes data to the html document, as `echo` would in PHP. You can use this like you would `writeln` in the standard library.
### Code
Each mini-program is mixin'd at compile time into a function with additional code stubbed into it. While in other languages this would mean limited functionality, in D this means you can do almost anything. You can import modules and functions, create functions, and most everything you would expect to be able to do within D. However, some functionality like declaring it as a module, and *maybe* multithreading won't work. (No idea why you would be multithreading it though, instead of using vibe.d's async)

You can even do things like `res.redirect(<path>)` within one of these mini-programs. But do not, I have **not** extensively tested this, and it may lead to unintended bugs.
## How to use it
It is very simple to use mood.
First, create an html file, then add whatever D code you need, and place it in the views folder like you would for a diet file. I will provide an example html file:
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

Next, all we have to do, is import the mood module, and give our html file to the router in our vibe.d URLRouter using `moodRender`.
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
## Includes
The syntax for includes is very simple:
`<include:file.html/>`
Includes in mood are similar to templates in diet.
+ You can nest includes.
+ You can use D code within includes.
+ You can put includes in folders.
## Templates
mood also comes with templates which make generate html tags easier. All but three (template, main, object) html tags are supported.
To use templates, import `mood.templates` in your html file, and run the function that corresponds to the tag.
You can use a template like:
```D
output("Hello World".h1);
```
Templates also have a second parameter, `attributes`, wich are inserted into the opening tag after the tag name and a space.
```D
output("Hello World".h1); // <h1>Hello World</h1>
output("Hello World".h1(`class="title"`)); // <h1 class="title">Hello World</h1>
output("Hello World".h1([
    `class`: `"title"`
])); // <h1 class="title">Hello World</h1>
```
## Contributing
If you have a suggestion, bug fix, or want a feature added, submit a PR, or an issue. Feedback is appreciated :)