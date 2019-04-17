module mood.hook;

import vibe.http.server: HTTPServerRequest, HTTPServerResponse;
import std.stdio: writeln;

alias MoodHookFn = void function(HTTPServerRequest, HTTPServerResponse);
alias MoodHookDg = void delegate(HTTPServerRequest, HTTPServerResponse);

private enum HookType
{
    Function,
    Delegate
}

private struct Hook
{
    HookType type;
    MoodHookFn fn;
    MoodHookDg dg;
}

private Hook[] hooks;

public void moodRegisterHook(MoodHookFn fn)
{
    hooks ~= Hook(HookType.Function, fn, null);
}

public void moodRegisterHook(MoodHookDg dg)
{
    hooks ~= Hook(HookType.Delegate, null, dg);
}

public void moodCallHooks(HTTPServerRequest req, HTTPServerResponse res)
{
    foreach(hook; hooks)
    {
        writeln(hook.type);
        if (hook.type == HookType.Function)
            hook.fn(req, res);
        else
            hook.dg(req, res);
    }
}
