const array<string> g_contentTypes = {
	"application/json",
	"application/x-www-form-urlencoded",
	"text/plain",
	"text/xml",
	"multipart/form-data"
};

enum BaseUrl
{
	Core,
	Live,
	Meet,
}

class RequestData
{
	string m_name = "";
	BaseUrl m_base = BaseUrl::Core;
	Net::HttpMethod m_method = Net::HttpMethod::Get;
	string m_path = "/";
	KeyedList m_query;
	KeyedList m_headers;
	string m_contentType = "application/json";
	string m_body = "{}";
	KeyedList m_variables;

	void Clear()
	{
		m_name = "";
		m_base = BaseUrl::Core;
		m_method = Net::HttpMethod::Get;
		m_path = "/";
		m_query.Clear();
		m_headers.Clear();
		m_contentType = "application/json";
		m_body = "{}";
		m_variables.Clear();
	}

	string GetBaseUrl()
	{
		switch (m_base) {
			case BaseUrl::Core: return NadeoServices::BaseURLCore();
			case BaseUrl::Live: return NadeoServices::BaseURLLive();
			case BaseUrl::Meet: return NadeoServices::BaseURLMeet();
		}
		throw("Invalid base URL type");
		return "";
	}

	string GetAudience()
	{
		switch (m_base) {
			case BaseUrl::Core: return "NadeoServices";
			case BaseUrl::Live: return "NadeoLiveServices";
			case BaseUrl::Meet: return "NadeoLiveServices";
		}
		throw("Invalid base URL type");
		return "";
	}

	bool MethodAcceptsData()
	{
		switch (m_method) {
			case Net::HttpMethod::Post:
			case Net::HttpMethod::Put:
			case Net::HttpMethod::Patch:
				return true;
		}
		return false;
	}

	string ReplaceVariables(const string &in str)
	{
		string ret = str;
		for (uint i = 0; i < m_variables.Length; i++) {
			auto item = m_variables[i];
			ret = ret.Replace("{" + item.m_key + "}", item.m_value);
		}
		return ret;
	}

	Net::HttpRequest@ MakeRequest()
	{
		auto req = NadeoServices::Request(GetAudience());
		req.Method = m_method;

		if (!m_path.StartsWith("/")) {
			throw("Request path should start with a forward slash (/).");
			return null;
		}

		for (uint i = 0; i < m_headers.Length; i++) {
			auto item = m_headers[i];
			req.Headers.Set(item.m_key, ReplaceVariables(item.m_value));
		}

		req.Headers.Set("Content-Type", ReplaceVariables(m_contentType));
		if (MethodAcceptsData()) {
			req.Body = ReplaceVariables(m_body);
		}

		req.Url = GetBaseUrl() + ReplaceVariables(m_path);
		for (uint i = 0; i < m_query.Length; i++) {
			auto item = m_query[i];
			if (i == 0) {
				req.Url += "?";
			} else {
				req.Url += "&";
			}
			req.Url += item.m_key + "=" + Net::UrlEncode(ReplaceVariables(item.m_value));
		}

		return req;
	}

	ResponseData DoAsync()
	{
		auto req = MakeRequest();
		req.Start();
		while (!req.Finished()) {
			yield();
		}
		return ResponseData(req);
	}

	void Render()
	{
		UI::BeginTabBar("RequestTabs");

		if (UI::BeginTabItem(Icons::Link + " Request query" + ColoredNumber(m_query.Length) + "###Query")) {
			m_query.Render();
			UI::EndTabItem();
		}

		if (UI::BeginTabItem(Icons::Kenney::List + " Request headers" + ColoredNumber(m_headers.Length) + "###Headers")) {
			m_headers.Render();
			UI::EndTabItem();
		}

		if (MethodAcceptsData() && UI::BeginTabItem(Icons::Code + " Request body")) {
			if (UI::BeginCombo("Content type", m_contentType)) {
				for (uint i = 0; i < g_contentTypes.Length; i++) {
					string contentType = g_contentTypes[i];
					if (UI::Selectable(contentType, m_contentType == contentType)) {
						m_contentType = contentType;
					}
				}
				UI::EndCombo();
			}
			m_body = UI::InputTextMultiline("##RequestBody", m_body, UI::GetContentRegionAvail());
			UI::EndTabItem();
		}

		if (UI::BeginTabItem(Icons::Th + " Variables" + ColoredNumber(m_variables.Length) + "###Variables")) {
			m_variables.Render();
			UI::EndTabItem();
		}

		UI::EndTabBar();
	}

	void FromJson(const Json::Value@ js)
	{
		Clear();

		auto jsName = js["name"];
		if (jsName !is null) {
			m_name = jsName;
		}

		auto jsBase = js["base"];
		if (jsBase !is null) {
			string strBase = jsBase;
			if (strBase == "core") { m_base = BaseUrl::Core; }
			else if (strBase == "live") { m_base = BaseUrl::Live; }
			else if (strBase == "meet") { m_base = BaseUrl::Meet; }
			else { throw("Unknown base \"" + strBase + "\""); }
		}

		auto jsMethod = js["method"];
		if (jsMethod !is null) {
			string strMethod = jsMethod;
			if (strMethod == "get") { m_method = Net::HttpMethod::Get; }
			else if (strMethod == "post") { m_method = Net::HttpMethod::Post; }
			else if (strMethod == "head") { m_method = Net::HttpMethod::Head; }
			else if (strMethod == "put") { m_method = Net::HttpMethod::Put; }
			else if (strMethod == "delete") { m_method = Net::HttpMethod::Delete; }
			else if (strMethod == "patch") { m_method = Net::HttpMethod::Patch; }
			else { throw("Unknown method \"" + strMethod + "\""); }
		}

		auto jsPath = js["path"];
		if (jsPath !is null) {
			m_path = jsPath;
		}

		m_query.FromJson(js["query"]);
		m_headers.FromJson(js["headers"]);

		auto jsContentType = js["content-type"];
		if (jsContentType !is null) {
			m_contentType = jsContentType;
		}

		auto jsBody = js["body"];
		if (jsBody !is null) {
			if (jsBody.GetType() == Json::Type::String) {
				m_body = jsBody;
			} else {
				m_body = Json::Write(jsBody, true);
			}
		}

		m_variables.FromJson(js["variables"]);
	}

	Json::Value@ ToJson()
	{
		auto ret = Json::Object();
		ret["name"] = m_name;
		ret["base"] = tostring(m_base).ToLower();
		ret["method"] = tostring(m_method).ToLower();
		ret["path"] = m_path;
		ret["query"] = m_query.ToJson();
		ret["headers"] = m_headers.ToJson();
		ret["content-type"] = m_contentType;
		ret["body"] = m_body;
		ret["variables"] = m_variables.ToJson();
		return ret;
	}
}

namespace RequestData
{
	array<RequestData@> LoadList(const string &in path)
	{
		auto js = Json::FromFile(path);
		if (js.GetType() == Json::Type::Array) {
			return LoadList(js);
		}
		return {};
	}

	array<RequestData@> LoadList(const Json::Value@ js)
	{
		array<RequestData@> ret;
		for (uint i = 0; i < js.Length; i++) {
			RequestData@ newRequestData = RequestData();
			newRequestData.FromJson(js[i]);
			ret.InsertLast(newRequestData);
		}
		return ret;
	}

	void SaveList(const array<RequestData@> &in list, const string &in path)
	{
		auto js = Json::Array();
		for (uint i = 0; i < list.Length; i++) {
			js.Add(list[i].ToJson());
		}
		Json::ToFile(path, js, true);
	}
}
