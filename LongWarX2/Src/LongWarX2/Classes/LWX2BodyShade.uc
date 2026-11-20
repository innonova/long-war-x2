// A translucent shading for a person's slot without a texture (LWX2EWBase.EmptySlotParent): an instance of our glass
// material (Tint, Opacity), as EW's eye shade darkens round the eyes.
class LWX2BodyShade extends Object;

static function MaterialInterface Make(string ParentPath, LinearColor Tint, float Opacity, Object InOuter)
{
	local Material Parent;
	local MaterialInstanceConstant MIC;

	Parent = Material(DynamicLoadObject(ParentPath, class'Material', true));
	if (Parent == none)
		return none;
	MIC = new(InOuter) class'MaterialInstanceConstant';
	MIC.SetParent(Parent);
	MIC.SetVectorParameterValue('Tint', Tint);
	MIC.SetScalarParameterValue('Opacity', Opacity);
	return MIC;
}
