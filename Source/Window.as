class ApiConsoleWindow
{
	array<RequestData@> m_routesCore = RequestData::LoadList("Routes/Core.json");
	array<RequestData@> m_routesLive = RequestData::LoadList("Routes/Live.json");
	array<RequestData@> m_routesMeet = RequestData::LoadList("Routes/Meet.json");

	array<RequestData@> m_routesSaved;

	RequestData m_request;
	ResponseData m_response;

	bool m_openSaveRoutePopup = false;
	string m_saveRouteName = "";

	bool m_waiting = false;

	ApiConsoleWindow()
	{
		auto jsSavedRoutes = Json::FromFile(IO::FromStorageFolder("SavedRoutes.json"));
		if (jsSavedRoutes.GetType() == Json::Type::Array) {
			m_routesSaved = RequestData::LoadList(jsSavedRoutes);
		}
	}

	void WriteSavedRoutes()
	{
		RequestData::SaveList(m_routesSaved, IO::FromStorageFolder("SavedRoutes.json"));
	}

	void Render()
	{
		if (!Setting_Visible) {
			return;
		}

		UI::SetNextWindowSize(1500, 600);
		if (UI::Begin("\\$f93" + Icons::Ticket + "\\$z Nadeo API Console###NadeoAPIConsole", Setting_Visible, UI::WindowFlags::NoCollapse | UI::WindowFlags::MenuBar)) {
			RenderMenuBar();
			RenderRequestBar();

			UI::Columns(2);
			m_request.Render();
			UI::NextColumn();
			m_response.Render();
			UI::Columns(1);

			RenderSavedRoutePopup();
		}
		UI::End();
	}

	void RenderMenuBar()
	{
		if (UI::BeginMenuBar()) {
			if (UI::BeginMenu("Settings")) {
				if (UI::MenuItem("Selectable raw response", "", Setting_ApiConsole_SelectableRawResponse)) {
					Setting_ApiConsole_SelectableRawResponse = !Setting_ApiConsole_SelectableRawResponse;
				}
				UI::SetItemTooltip(
					"This makes the raw response selectable so it can be more easily copied. Due to a\n"
					"limitation in ImGui, this does not enable word wrapping, so is disabled by default.");
				UI::EndMenu();
			}

			if (UI::BeginMenu("Routes")) {
				if (UI::MenuItem("Clear current request")) {
					m_request.Clear();
				}
				UI::Separator();
				RenderMenuRoutes("Core", m_routesCore);
				RenderMenuRoutes("Live", m_routesLive);
				RenderMenuRoutes("Meet", m_routesMeet);
				UI::Separator();
				RenderMenuSavedRoutes();
				if (UI::MenuItem(Icons::PlusCircle + " Save current request")) {
					m_openSaveRoutePopup = true;
				}
				UI::EndMenu();
			}

			if (UI::BeginMenu("Utilities")) {
				if (UI::MenuItem("Copy my account ID")) {
					IO::SetClipboard(NadeoServices::GetAccountID());
				}
				UI::EndMenu();
			}

			if (UI::BeginMenu("Help")) {
				if (UI::MenuItem(Icons::QuestionCircle + " Web Services Documentation")) {
					OpenBrowserURL("https://webservices.openplanet.dev/");
				}
				UI::Separator();
				if (UI::MenuItem(Icons::Discord + " Openplanet Discord")) {
					OpenBrowserURL("https://openplanet.dev/link/discord");
				}
				UI::EndMenu();
			}

			UI::EndMenuBar();
		}
	}

	void RenderMenuRoutes(const string &in collectionName, const array<RequestData@> &in routes)
	{
		if (UI::BeginMenu(collectionName, routes.Length > 0)) {
			for (uint i = 0; i < routes.Length; i++) {
				auto route = routes[i];

				string name = route.m_name;
				if (name.Length == 0) {
					name = route.m_path;
				}

				if (UI::MenuItem("\\$f93" + Icons::FolderOpen + "\\$z " + name + "##route" + i)) {
					m_request = route;
				}
			}
			UI::EndMenu();
		}
	}

	void RenderMenuSavedRoutes()
	{
		if (UI::BeginMenu(Icons::Star + " Saved routes", m_routesSaved.Length > 0)) {
			for (uint i = 0; i < m_routesSaved.Length; i++) {
				auto route = m_routesSaved[i];

				string name = route.m_name;
				if (name.Length == 0) {
					name = route.m_path;
				}

				if (UI::BeginMenu(name + "##route" + i)) {
					if (UI::MenuItem("\\$f93" + Icons::FolderOpen + "\\$z Load " + name)) {
						m_request = route;
					}
					UI::Separator();
					if (UI::MenuItem(Icons::FloppyO + " Overwrite with current")) {
						string tempName = route.m_name;
						route = m_request;
						route.m_name = tempName;
						WriteSavedRoutes();
					}
					if (UI::MenuItem(Icons::MinusCircle + " Delete route")) {
						m_routesSaved.RemoveAt(i);
						WriteSavedRoutes();
					}
					UI::EndMenu();
				}
			}
			UI::EndMenu();
		}
	}

	void RenderRequestBar()
	{
		UI::BeginDisabled(m_waiting);
		UI::SetNextItemWidth(100);
		if (UI::BeginCombo("##BaseURLType", tostring(m_request.m_base))) {
			for (int i = 0; i < 3; i++) {
				if (UI::Selectable(tostring(BaseUrl(i)), m_request.m_base == BaseUrl(i))) {
					m_request.m_base = BaseUrl(i);
				}
			}
			UI::EndCombo();
		}
		UI::SameLine();
		UI::SetNextItemWidth(100);
		if (UI::BeginCombo("##RequestMethod", tostring(m_request.m_method).ToUpper())) {
			for (int i = 0; i < 6; i++) {
				if (UI::Selectable(tostring(Net::HttpMethod(i)).ToUpper(), m_request.m_method == Net::HttpMethod(i))) {
					m_request.m_method = Net::HttpMethod(i);
				}
			}
			UI::EndCombo();
		}
		UI::SameLine();
		UI::PushFont(g_fontMono);
		UI::TextDisabled(m_request.GetBaseUrl());
		UI::SameLine();
		UI::SetNextItemWidth(UI::GetContentRegionAvail().x - 60);
		bool pathModified = false;
		m_request.m_path = UI::InputText("##PathInput", m_request.m_path, pathModified);
		UI::PopFont();
		UI::SameLine();
		if (UI::ButtonColored(Icons::ArrowRight, 0.05f, 0.6f, 0.6f, vec2(UI::GetContentRegionAvail().x, 0))) {
			startnew(CoroutineFunc(StartRequestAsync));
		}
		UI::EndDisabled();
	}

	void RenderSavedRoutePopup()
	{
		if (m_openSaveRoutePopup) {
			m_openSaveRoutePopup = false;
			m_saveRouteName = "";
			UI::OpenPopup("Save current request");
		}

		UI::SetNextWindowSize(0, 0);
		if (UI::BeginPopupModal("Save current request", UI::WindowFlags::NoSavedSettings | UI::WindowFlags::NoResize)) {
			bool pressedEnter = false;
			UI::Text("Please enter a name for this route:");
			if (UI::IsWindowAppearing()) {
				UI::SetKeyboardFocusHere();
			}
			UI::SetNextItemWidth(250);
			m_saveRouteName = UI::InputText("##SaveRouteName", m_saveRouteName, pressedEnter, UI::InputTextFlags::EnterReturnsTrue);
			if (UI::ButtonColored(Icons::FloppyO + " Save", 0.4f) || pressedEnter) {
				RequestData@ newRequest = RequestData();
				newRequest = m_request;
				newRequest.m_name = m_saveRouteName;
				m_routesSaved.InsertLast(newRequest);
				WriteSavedRoutes();
				UI::CloseCurrentPopup();
			}
			UI::SameLine();
			if (UI::Button("Cancel")) {
				UI::CloseCurrentPopup();
			}
			UI::EndPopup();
		}
	}

	void StartRequestAsync()
	{
		m_waiting = true;
		m_response = ResponseData();
		m_response = m_request.DoAsync();
		m_waiting = false;
	}
}
