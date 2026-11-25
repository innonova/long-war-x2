// XCOM 2's story told at headquarters (its advisors' comm-link portraits and voice: Central over the armory's customization,
// aek's screenshot 2026-11-25) has no place in Long War's: each conversation the comm link opens for is logged by its
// narrative and stopped (UINarrativeMgr.StopNarrative, which runs its completion as if heard out). As the missions' advisor
// lines are already silenced (LWX2Species, NoBeginnerVO).
class UIScreenListener_LWX2NoHQNarrative extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	Silence(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	Silence(Screen);
}

function Silence(UIScreen Screen)
{
	local UINarrativeMgr Mgr;
	local array<XComNarrativeMoment> Moments;
	local XComNarrativeMoment M;
	local int i;

	if (UINarrativeCommLink(Screen) == none || XComHQPresentationLayer(Screen.Movie.Pres) == none)
		return;
	Mgr = Screen.Movie.Pres.m_kNarrativeUIMgr;
	if (Mgr == none)
		return;
	for (i = 0; i < Mgr.m_arrConversations.Length; i++)
		if (Mgr.m_arrConversations[i].NarrativeMoment != none && Moments.Find(Mgr.m_arrConversations[i].NarrativeMoment) == INDEX_NONE)
			Moments.AddItem(Mgr.m_arrConversations[i].NarrativeMoment);
	foreach Moments(M)
	{
		`log("LongWarX2: XCOM 2's narrative at headquarters stopped:" @ PathName(M), , 'LongWarX2');
		Mgr.StopNarrative(M);
	}
}

defaultproperties
{
	ScreenClass = none;
}
