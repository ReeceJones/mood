/*
Not exactly an amazing example, but it should give you an idea of what mood is all about.
*/

import vibe.d;
import mood.vibe;
import backend.db;

void newBulletin(HTTPServerRequest req, HTTPServerResponse res)
{
	if ("message" in req.form && "name" in req.form)
	{
		string name = req.form["name"];
		string message = req.form["message"];
		if (name.length == 0 || message.length == 0)
			res.redirect("/error");
		else
		{
			bulletin.insert([
				"name": name,
				"message": message
			]);
		}
	}
	else
		res.redirect("/error");

	res.redirect("/");
}

shared static this()
{
	auto router = new URLRouter;
	router.get("/", moodRender!"index.html");
	router.get("/error", moodRender!"error.html");

	router.post("/post", &newBulletin);
	auto settings = new HTTPServerSettings;
	settings.port = 9001;
	settings.bindAddresses = ["::1", "0.0.0.0"];

	listenHTTP(settings, router);
}
