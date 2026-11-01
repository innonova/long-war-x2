// An alien stunned by the arc thrower (X2Ability_LWArcThrower): taken alive, off the field, and noted in the
// Geoscape's state (which comes back from the mission with it) to come home as Long War's captive.
class X2Effect_LWCapture extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit Unit;
	local XComGameState_LWStrategy S;

	Unit = XComGameState_Unit(kNewTargetState);
	if (Unit == none)
		return;
	Unit.SetUnitFloatValue('LWCaptured', 1, eCleanup_Never);
	Unit.RemoveUnitFromPlay();
	if (class'XComGameState_LWStrategy'.static.Get() != none)
	{
		S = XComGameState_LWStrategy(NewGameState.ModifyStateObject(class'XComGameState_LWStrategy', class'XComGameState_LWStrategy'.static.Get().ObjectID));
		S.PendingCaptives.AddItem(Unit.GetMyTemplate().CharacterGroupName);
	}
	`log("LongWarX2: arc thrower: took" @ Unit.GetMyTemplateName() @ "(" $ Unit.GetMyTemplate().CharacterGroupName $ ") alive", , 'LongWarX2');
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	if (EffectApplyResult == 'AA_Success')
		class'X2Action_RemoveUnit'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
}
