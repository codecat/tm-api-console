class ResponseData
{
	string m_error = "";
	int m_code = 0;
	dictionary@ m_headers;
	string m_raw = "";

	string m_pretty = "";

	ResponseData() {}
	ResponseData(Net::HttpRequest@ req)
	{
		m_error = req.Error();
		m_code = req.ResponseCode();
		@m_headers = req.ResponseHeaders();
		m_raw = req.String();

		string contentType;
		m_headers.Get("content-type", contentType);
		if (contentType == "application/json") {
			m_pretty = Json::Write(req.Json(), true);
		}
	}

	void Render()
	{
		if (m_code == 0) {
			return;
		}

		UI::BeginTabBar("ResponseTabs");

		if (UI::BeginTabItem(Icons::Kenney::List + " Response headers")) {
			if (UI::BeginChild("Container")) {
				UI::Text("Response code \\$f93" + m_code);
				UI::PushFont(g_fontMono);
				auto keys = m_headers.GetKeys();
				for (uint i = 0; i < keys.Length; i++) {
					string key = keys[i];
					string value;
					m_headers.Get(key, value);
					UI::Text("\\$f93" + key + "\\$z: " + value);
				}
				UI::PopFont();
				UI::EndChild();
			}
			UI::EndTabItem();
		}

		if (m_pretty.Length > 0 && UI::BeginTabItem(Icons::FileTextO + " Pretty response")) {
			UI::PushFont(g_fontMono);
			UI::InputTextMultiline("##ResponsePretty", m_pretty, UI::GetContentRegionAvail(), UI::InputTextFlags::ReadOnly);
			UI::PopFont();
			UI::EndTabItem();
		}

		if (UI::BeginTabItem(Icons::FileO + " Raw response")) {
			UI::PushFont(g_fontMono);
			if (Setting_ApiConsole_SelectableRawResponse) {
				UI::InputTextMultiline("##ResponseRaw", m_raw, UI::GetContentRegionAvail(), UI::InputTextFlags::ReadOnly);
			} else {
				if (UI::BeginChild("Container")) {
					UI::TextWrapped(m_raw);
					UI::EndChild();
				}
			}
			UI::PopFont();
			UI::EndTabItem();
		}

		UI::EndTabBar();
	}
}
