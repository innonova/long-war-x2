// Long War's classes choose one of three perks a rank (features/lw-classes.md); XCOM 2's
// promotion screen shows two, its heroes' screen (the factions') shows them all. So for a
// soldier of a Long War class the first is replaced by the second, with Long War's rules
// (LWX2PromotionScreen).
class UIScreenListener_LongWarX2Promotion extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UIArmory_Promotion Promotion;
	local LWX2PromotionScreen Hero;
	local XComGameState_Unit Unit;
	local XComHQPresentationLayer Pres;

	Promotion = UIArmory_Promotion(Screen);
	if (Promotion == none || LWX2PromotionScreen(Screen) != none || UIArmory_PromotionHero(Screen) != none || UIArmory_PromotionPsiOp(Screen) != none)
		return;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Promotion.UnitReference.ObjectID));
	if (Unit == none || Left(string(Unit.GetSoldierClassTemplateName()), 4) != "LWS_")
		return;
	Pres = `HQPRES;
	Pres.ScreenStack.Pop(Promotion);
	Hero = LWX2PromotionScreen(Pres.ScreenStack.Push(Pres.Spawn(class'LWX2PromotionScreen', Pres), Pres.Get3DMovie()));
	Hero.InitPromotion(Unit.GetReference(), true);
	`log("LongWarX2: promotion: Long War's promotion screen for" @ Unit.GetFullName() @ "(" $ Unit.GetSoldierClassTemplateName() $ ")", , 'LongWarX2');
}

defaultproperties
{
	ScreenClass = none;
}
