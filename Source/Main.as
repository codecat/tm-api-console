UI::Font@ g_fontMono;

ApiConsoleWindow@ g_window;

void Main()
{
#if SIG_DEVELOPER
	NadeoServices::AddAudience("NadeoServices");
	NadeoServices::AddAudience("NadeoLiveServices");

	@g_fontMono = UI::LoadFont("DroidSansMono.ttf", 16);

	@g_window = ApiConsoleWindow();
#else
	warn("Developer mode is required to use the Nadeo API Console.");
#endif
}

void RenderMenu()
{
#if SIG_DEVELOPER
	if (UI::MenuItem("\\$f93" + Icons::Ticket + "\\$z Nadeo API Console", "", Setting_Visible)) {
		Setting_Visible = !Setting_Visible;
	}
#endif
}

void RenderInterface()
{
#if SIG_DEVELOPER
	g_window.Render();
#endif
}

string ColoredNumber(int n)
{
	if (n == 0) { return ""; }
	return " \\$f93(" + n + ")\\$z";
}
