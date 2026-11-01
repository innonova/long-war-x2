// Long War's classes choose one of three perks a rank (features/lw-classes.md); XCOM 2's
// promotion screen shows two, its heroes' screen (the factions') shows them all. So for a
// soldier of a Long War class the first is replaced by the second.
class UIScreenListener_LongWarX2Promotion extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIArmory_Promotion Promotion;
	local UIArmory_PromotionHero Hero;
	local XComGameState_Unit Unit;
	local XComHQPresentationLayer Pres;

	Promotion = UIArmory_Promotion(Screen);
	if (Promotion == none || UIArmory_PromotionHero(Screen) != none || UIArmory_PromotionPsiOp(Screen) != none)
		return;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Promotion.UnitReference.ObjectID));
	if (Unit == none || Left(string(Unit.GetSoldierClassTemplateName()), 4) != "LWS_")
		return;
	Pres = `HQPRES;
	Pres.ScreenStack.Pop(Promotion);
	Hero = UIArmory_PromotionHero(Pres.ScreenStack.Push(Pres.Spawn(class'UIArmory_PromotionHero', Pres), Pres.Get3DMovie()));
	Hero.InitPromotion(Unit.GetReference(), true);
	`log("LongWarX2: promotion: the heroes' screen for" @ Unit.GetFullName() @ "(" $ Unit.GetSoldierClassTemplateName() $ ")", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
