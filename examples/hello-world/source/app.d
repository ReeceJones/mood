import std.stdio;

import vibe.d;
import mood.vibe;
import mood.hook;

shared static this()
{
	int foo = 1337;

	auto router = new URLRouter;

	router.get("/", moodRender!("index.html", foo));
	router.get("/foo", moodRender!"foo.html");
	auto settings = new HTTPServerSettings;
	settings.port = 9001;
	settings.bindAddresses = ["::1", "0.0.0.0"];

	listenHTTP(settings, router);
}
