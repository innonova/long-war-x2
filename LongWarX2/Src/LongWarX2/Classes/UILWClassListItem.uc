// A class in Commander's Choice's chooser (UILWChooseClass): XCOM 2's class row without the training time (the class is the
// soldier's at once).
class UILWClassListItem extends UIInventory_ClassListItem;

simulated function PopulateData(optional bool bRealizeDisabled)
{
	MC.BeginFunctionOp("populateData");
	MC.QueueString(ItemComodity.Image);
	MC.QueueString(ItemComodity.Title);
	MC.QueueString("");
	MC.QueueString(ItemComodity.Desc);
	MC.EndOp();
	if (bRealizeDisabled)
		RealizeDisabledState();
}
