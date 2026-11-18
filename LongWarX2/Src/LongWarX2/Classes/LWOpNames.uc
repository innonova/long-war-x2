// Enemy Within's operation names for Long War's missions (features/strategy-flow.md): XGMission.GenerateOpName, with EW's
// words from the player's install (lw-words.mjs, makeOpNameWords: EW's [XGMission] copied as it is). "Operation" and one of
// each list at random; the Temple Ship is Operation Avenger, the HQ assault Operation Ashes and Temples, and the council's
// meld tutorial mission its own pair. Without the words, XCOM 2's name stays.
class LWOpNames extends Object;

var localized array<string> m_aFirstOpName, m_aSecondOpName;
var localized string m_strOpRandom, m_strOpAvenger, m_strOpAshes;

/** The name for a mission of Long War's kind (XComGameState_LWStrategy.PendingKind) and, for a council mission, its EW
 *  number (EFCMission); "" without EW's words. */
static function string For(int Kind, optional int CouncilMission = -1)
{
	local XGParamTag Tag;

	if (default.m_aFirstOpName.Length == 0 || default.m_aSecondOpName.Length == 0 || default.m_strOpRandom == "")
		return "";
	// (EW's mission types: eMission_Final, the Temple Ship; eMission_HQAssault.)
	if (Kind == 6 && default.m_strOpAvenger != "")
		return default.m_strOpAvenger;
	if (Kind == 7 && default.m_strOpAshes != "")
		return default.m_strOpAshes;
	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	// (eFCM_MeldTutorial.)
	if (Kind == 10 && CouncilMission == 30 && default.m_aFirstOpName.Length > 48 && default.m_aSecondOpName.Length > 38)
	{
		Tag.StrValue0 = default.m_aFirstOpName[48];
		Tag.StrValue1 = default.m_aSecondOpName[38];
	}
	else
	{
		Tag.StrValue0 = default.m_aFirstOpName[Rand(default.m_aFirstOpName.Length)];
		Tag.StrValue1 = default.m_aSecondOpName[Rand(default.m_aSecondOpName.Length)];
	}
	return class'XComLocalizer'.static.ExpandString(default.m_strOpRandom);
}
