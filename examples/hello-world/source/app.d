import std.stdio;

import vibe.d;
import mood.vibe;

shared static this()
{
	auto router = new URLRouter;
	router.get("/test", moodRender!"test.html");
	router.get("/foo", moodRender!"foo.html");
	router.get("/bar", moodRender!"bar.html");
	auto settings = new HTTPServerSettings;
	settings.port = 9001;
	settings.bindAddresses = ["::1", "0.0.0.0"];

	listenHTTP(settings, router);
}
