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

/**
 * Register a hook.
 * 
 * Registers a hook that is called whenever a page is loaded.
 * Params:
 *  fn = The function that is going to be called on page load
 */
public void moodRegisterHook(MoodHookFn fn)
{
    hooks ~= Hook(HookType.Function, fn, null);
}

/**
 * Register a hook.
 * 
 * Registers a hook that is called whenever a page is loaded.
 * Params:
 *  dg = The delegate that is going to be called on page load
 */
public void moodRegisterHook(MoodHookDg dg)
{
    hooks ~= Hook(HookType.Delegate, null, dg);
}

/**
 * Calls all hooks.
 *
 * Called whenever a page is loaded. There is no need to call this yourself.
 * Params:
 *  req = The HTTPServerRequest
 *  res = The HTTPServerResponse
 */
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
