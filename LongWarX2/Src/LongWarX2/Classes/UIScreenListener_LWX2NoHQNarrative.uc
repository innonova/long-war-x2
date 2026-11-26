// XCOM 2's story told at headquarters (its advisors' comm-link portraits and voice: Central over the armory's customization,
// aek's screenshot 2026-11-25) has no place in Long War's: each conversation the comm link opens for is logged by its
// narrative and stopped (UINarrativeMgr.StopNarrative, which runs its completion as if heard out). As the missions' advisor
// lines are already silenced (LWX2Species, NoBeginnerVO). (The comm link's own init or focus seldom comes: StopAll is also
// asked by EW's base, LWX2EWBase.SilenceNarrative.)
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
	if (UINarrativeCommLink(Screen) != none)
		StopAll(Screen.Movie.Pres);
}

/** Every conversation XCOM 2's narrative manager holds at headquarters stopped, logged by its narrative. Also asked each
 *  quarter second by EW's base (LWX2EWBase.SilenceNarrative): XCOM 2's objectives start theirs on game events (Central on
 *  a first Customize in the armory, 2026-11-26), and the comm link, made once, then only shows, its screen's events gone. */
static function StopAll(XComPresentationLayerBase Pres)
{
	local UINarrativeMgr Mgr;
	local array<XComNarrativeMoment> Moments;
	local XComNarrativeMoment M;
	local int i;

	if (XComHQPresentationLayer(Pres) == none)
		return;
	Mgr = Pres.m_kNarrativeUIMgr;
	if (Mgr == none || Mgr.m_arrConversations.Length == 0)
		return;
	for (i = 0; i < Mgr.m_arrConversations.Length; i++)
		if (Mgr.m_arrConversations[i].NarrativeMoment != none && Moments.Find(Mgr.m_arrConversations[i].NarrativeMoment) == INDEX_NONE)
			Moments.AddItem(Mgr.m_arrConversations[i].NarrativeMoment);
	foreach Moments(M)
	{
		`log("LongWarX2: XCOM 2's narrative at headquarters stopped:" @ PathName(M), , 'LongWarX2');
		Mgr.StopNarrative(M);
	}
	// (The screens it had hidden for its "cinematic" shown again, as its own end does, StartFadeFromBlack: the Customize's
	// back button and soldier arrows had stayed hidden. Only in that mode, UIScreenStack.ShowUIForCinematics.)
	if (Moments.Length > 0)
		Pres.ShowUIForCinematics();
}

defaultproperties
{
	ScreenClass = none;
}
