# Long War X2's template plot as T3D (features/lw-missions.md, "real XCOM 2 maps"): a box level volume, a group spawn, a
# parcel slot, and one sample of each actor kind the plot writer clones for an Enemy Within map. Pasted into a blank map
# in the SDK editor (Ctrl+V in the viewport), its AI paths built (the tile grid), saved as tools/maps/LWX2_EWPlotTemplate.umap.
#   python3 tools/maps/template.py > template.t3d
H = 1536.0          # half size in X and Y (32 tiles each way)
Z0, Z1 = -48.0, 1104.0   # floor below 0, 12 tiles of height
def face(vs):
    import numpy as np
    v = [np.array(p, float) for p in vs]
    n = np.cross(v[1]-v[0], v[2]-v[0]); n = n/np.linalg.norm(n)
    return v, n
boxes = {
 '-X': [(-H,-H,Z0),(-H,-H,Z1),(-H,H,Z1),(-H,H,Z0)],
 '+Y': [(-H,H,Z0),(-H,H,Z1),(H,H,Z1),(H,H,Z0)],
 '+X': [(H,H,Z0),(H,H,Z1),(H,-H,Z1),(H,-H,Z0)],
 '-Y': [(H,-H,Z0),(H,-H,Z1),(-H,-H,Z1),(-H,-H,Z0)],
 '+Z': [(-H,-H,Z1),(H,-H,Z1),(H,H,Z1),(-H,H,Z1)],
 '-Z': [(-H,H,Z0),(H,H,Z0),(H,-H,Z0),(-H,-H,Z0)],
}
want = {'-X':(-1,0,0),'+X':(1,0,0),'-Y':(0,-1,0),'+Y':(0,1,0),'-Z':(0,0,-1),'+Z':(0,0,1)}
f = lambda x: ('%+013.6f' % x).replace('+', '+0', 0)
def fmt(v): return ','.join(('%+013.6f' % c) for c in v)
polys = []
for k, (name, vs) in enumerate(boxes.items()):
    v, n = face(vs)
    assert tuple(round(c) for c in n) == want[name], (name, n)
    u = v[1]-v[0]; u = u/ (sum(c*c for c in u) ** 0.5)
    w = v[3]-v[0]; w = w/ (sum(c*c for c in w) ** 0.5)
    polys.append(f'''               Begin Polygon Flags=3584 Link={k}
                  Origin   {fmt(v[0])}
                  Normal   {fmt(n)}
                  TextureU {fmt(w)}
                  TextureV {fmt(u)}
''' + ''.join(f'                  Vertex   {fmt(p)}\n' for p in v) + '               End Polygon\n')
t3d = f'''Begin Map
   Begin Level
      Begin Actor Class=XComLevelVolume Name=XComLevelVolume_0 Archetype=XComLevelVolume'XComGame.Default__XComLevelVolume'
         Begin Object Class=BrushComponent Name=BrushComponent0 ObjName=BrushComponent_0 Archetype=BrushComponent'XComGame.Default__XComLevelVolume:BrushComponent0'
            Brush=Model'Model_LV'
         End Object
         Begin Brush Name=Model_LV
            Begin PolyList
{''.join(polys)}            End PolyList
         End Brush
         Brush=Model'Model_LV'
         BrushComponent=BrushComponent'BrushComponent_0'
         Components(0)=BrushComponent'BrushComponent_0'
         CollisionComponent=BrushComponent'BrushComponent_0'
         Location=(X=0.000000,Y=0.000000,Z=0.000000)
         Tag="XComLevelVolume"
      End Actor
      Begin Actor Class=XComGroupSpawn Name=XComGroupSpawn_0 Archetype=XComGroupSpawn'XComGame.Default__XComGroupSpawn'
         Location=(X=0.000000,Y=-1248.000000,Z=16.000000)
      End Actor
      Begin Actor Class=XComParcel Name=XComParcel_0 Archetype=XComParcel'XComGame.Default__XComParcel'
         SizeX=32
         SizeY=32
         bFacingNorth=True
         bFacingEast=True
         bFacingSouth=True
         bFacingWest=True
         CanBeObjectiveParcel=True
         ParcelDef=(eSize=eParcelSizeType_Small,ObjectiveSpawnDensity=EParcelSpawnDensity_Dispersed,eFacing=EParcelFacingType_None)
         eFacing=EParcelFacingType_None
         Location=(X=0.000000,Y=0.000000,Z=16.000000)
         DrawScale3D=(X=32.000000,Y=32.000000,Z=1.000000)
      End Actor
      Begin Actor Class=XComLevelActor Name=XComLevelActor_0 Archetype=XComLevelActor'XComGame.Default__XComLevelActor'
         Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0 ObjName=StaticMeshComponent_0 Archetype=StaticMeshComponent'XComGame.Default__XComLevelActor:StaticMeshComponent0'
            StaticMesh=StaticMesh'EngineMeshes.Cube'
         End Object
         StaticMeshComponent=StaticMeshComponent'StaticMeshComponent_0'
         Components(0)=StaticMeshComponent'StaticMeshComponent_0'
         CollisionComponent=StaticMeshComponent'StaticMeshComponent_0'
         Location=(X=0.000000,Y=1920.000000,Z=-2000.000000)
      End Actor
      Begin Actor Class=PointLightMovable Name=PointLightMovable_0 Archetype=PointLightMovable'Engine.Default__PointLightMovable'
         Location=(X=0.000000,Y=1920.000000,Z=-1800.000000)
      End Actor
      Begin Actor Class=SpotLightMovable Name=SpotLightMovable_0 Archetype=SpotLightMovable'Engine.Default__SpotLightMovable'
         Location=(X=200.000000,Y=1920.000000,Z=-1800.000000)
      End Actor
   End Level
End Map
'''
import sys
sys.stdout.write(t3d.replace('\n', '\r\n'))
