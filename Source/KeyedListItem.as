class KeyedListItem
{
	string m_key;
	string m_value;

	KeyedListItem() {}
	KeyedListItem(const KeyedListItem &in other)
	{
		m_key = other.m_key;
		m_value = other.m_value;
	}
	KeyedListItem(const string &in key, const string &in value)
	{
		m_key = key;
		m_value = value;
	}
}
