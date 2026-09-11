"""Original low-poly mesh authoring source for Jin Deng Xing. Python standard library only.
Run from any directory; exports articulated GLBs, nodal animation clips and mesh inventory.
"""
from pathlib import Path
import math, json, struct
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models'
OUT.mkdir(parents=True,exist_ok=True)
TAU=math.tau

def add(a,b): return tuple(x+y for x,y in zip(a,b))
def sub(a,b): return tuple(x-y for x,y in zip(a,b))
def mul(a,s): return tuple(x*s for x in a)
def cross(a,b): return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def norm(a):
 l=math.sqrt(sum(x*x for x in a));return mul(a,1/l) if l>1e-9 else (0,1,0)
def col(h): return tuple((int(h[i:i+2],16)/255)**2.2 for i in (0,2,4))+(1.,)
INK=col('283b3b'); GOLD=col('c8a66b'); SKIN=col('c6b391'); SILVER=col('c2d4cb'); RED=col('a44739'); WOOD=col('655144'); PALE=col('ded7bc')

class Mesh:
 def __init__(self): self.p=[];self.n=[];self.c=[]
 def tri(self,a,b,c,color):
  n=norm(cross(sub(b,a),sub(c,a)))
  self.p.extend([a,b,c]);self.n.extend([n]*3);self.c.extend([color]*3)
 def quad(self,a,b,c,d,color): self.tri(a,b,c,color);self.tri(a,c,d,color)
 def loft(self,sections,color,n=12,fold=0.0):
  rings=[]
  for y,rx,rz,cx,cz in sections:
   rings.append([(cx+math.cos(i*TAU/n)*rx*(1+fold*(i%2)),y,cz+math.sin(i*TAU/n)*rz*(1+fold*(i%2))) for i in range(n)])
  for k in range(len(rings)-1):
   for i in range(n):
    j=(i+1)%n;self.quad(rings[k][i],rings[k+1][i],rings[k+1][j],rings[k][j],color)
  for ring,rev in [(rings[0],True),(rings[-1],False)]:
   center=tuple(sum(p[j] for p in ring)/n for j in range(3))
   for i in range(n):
    a,b=ring[i],ring[(i+1)%n]
    self.tri(center,b,a,color) if rev else self.tri(center,a,b,color)
 def ellipsoid(self,center,scale,color,n=10,rows=6):
  sections=[]
  for j in range(rows+1):
   a=-math.pi/2+j*math.pi/rows
   sections.append((center[1]+math.sin(a)*scale[1],max(.001,math.cos(a)*scale[0]),max(.001,math.cos(a)*scale[2]),center[0],center[2]))
  self.loft(sections,color,n)
 def tube(self,path,radii,color,n=6):
  rings=[]
  for i,p in enumerate(path):
   t=norm(sub(path[min(i+1,len(path)-1)],path[max(0,i-1)]))
   u=norm(cross(t,(0,1,0) if abs(t[1])<.9 else (1,0,0)));v=cross(t,u)
   rings.append([add(p,add(mul(u,math.cos(j*TAU/n)*radii[i]),mul(v,math.sin(j*TAU/n)*radii[i]))) for j in range(n)])
  for k in range(len(rings)-1):
   for j in range(n): self.quad(rings[k][j],rings[k+1][j],rings[k+1][(j+1)%n],rings[k][(j+1)%n],color)
  for ring,center,rev in [(rings[0],path[0],True),(rings[-1],path[-1],False)]:
   for j in range(n):
    a,b=ring[j],ring[(j+1)%n]
    self.tri(center,b,a,color) if rev else self.tri(center,a,b,color)
 def blade(self,outline,thickness,color,edge=None):
  # The profile lies in X/Z; a raised central ridge supplies a real bevel.
  cx=sum(p[0] for p in outline)/len(outline);cz=sum(p[1] for p in outline)/len(outline)
  for i,(x,z) in enumerate(outline):
   nx,nz=outline[(i+1)%len(outline)]
   self.tri((cx,thickness,cz),(x,0,z),(nx,0,nz),color)
   self.tri((cx,-thickness,cz),(nx,0,nz),(x,0,z),edge or color)
 def ribbon(self,points,widths,color):
  for i in range(len(points)-1):
   a,b=points[i:i+2];wa,wb=widths[i:i+2]
   self.quad(add(a,(-wa,0,0)),add(a,(wa,0,0)),add(b,(wb,0,0)),add(b,(-wb,0,0)),color)
 def translate(self,offset): self.p=[add(v,offset) for v in self.p];return self

class GLB:
 def __init__(self,name):
  self.data=bytearray();self.j={'asset':{'version':'2.0','generator':'JinDengXing original mesh workshop'},'scene':0,'scenes':[{'nodes':[0]}],'nodes':[{'name':name,'children':[]}],'meshes':[],'buffers':[],'bufferViews':[],'accessors':[],'materials':[{'name':'InkVertexPalette','pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':.92},'doubleSided':True}]};self.tris=0
 def access(self,values,kind):
  while len(self.data)%4:self.data.append(0)
  offset=len(self.data);flat=[x for v in values for x in v];self.data+=struct.pack('<'+'f'*len(flat),*flat)
  view=len(self.j['bufferViews']);self.j['bufferViews'].append({'buffer':0,'byteOffset':offset,'byteLength':len(flat)*4})
  acc={'bufferView':view,'componentType':5126,'count':len(values),'type':kind}
  if kind in ['VEC3','SCALAR']:
   acc['min']=[min(v[i] for v in values) for i in range(len(values[0]))];acc['max']=[max(v[i] for v in values) for i in range(len(values[0]))]
  idx=len(self.j['accessors']);self.j['accessors'].append(acc);return idx
 def node(self,name,parent=0,pos=(0,0,0),mesh=None,scale=None):
  node={'name':name,'translation':list(pos),'children':[]}
  if scale: node['scale']=list(scale)
  if mesh and mesh.p:
   node['mesh']=len(self.j['meshes']);self.j['meshes'].append({'name':name,'primitives':[{'attributes':{'POSITION':self.access(mesh.p,'VEC3'),'NORMAL':self.access(mesh.n,'VEC3'),'COLOR_0':self.access(mesh.c,'VEC4')},'material':0}]});self.tris+=len(mesh.p)//3
  idx=len(self.j['nodes']);self.j['nodes'].append(node);self.j['nodes'][parent]['children'].append(idx);return idx
 def clip(self,name,channels):
  times=self.access([(0.,),(.25,),(.5,),(.75,),(1.,)],'SCALAR');a={'name':name,'samplers':[],'channels':[]}
  for node,axis,angles in channels:
   values=[]
   for angle in angles:
    q=[0.,0.,0.,math.cos(angle/2)];q[axis]=math.sin(angle/2);values.append(q)
   idx=len(a['samplers']);a['samplers'].append({'input':times,'output':self.access(values,'VEC4'),'interpolation':'LINEAR'});a['channels'].append({'sampler':idx,'target':{'node':node,'path':'rotation'}})
  self.j.setdefault('animations',[]).append(a)
 def save(self,name):
  self.j['buffers']=[{'byteLength':len(self.data)}];payload=json.dumps(self.j,separators=(',',':')).encode();payload+=b' '*((-len(payload))%4)
  while len(self.data)%4:self.data.append(0)
  content=struct.pack('<III',0x46546c67,2,12+8+len(payload)+8+len(self.data))+struct.pack('<II',len(payload),0x4e4f534a)+payload+struct.pack('<II',len(self.data),0x004e4942)+self.data
  (OUT/(name+'.glb')).write_bytes(content)
  return {'file':name+'.glb','triangles':self.tris,'mesh_parts':len(self.j['meshes']),'clips':[a['name'] for a in self.j.get('animations',[])],'bytes':len(content)}

def weapon(kind):
 m=Mesh()
 if kind in ['long_spear','iron_staff','trident','oar','brush']:
  length={'long_spear':2.2,'iron_staff':2.,'trident':2.0,'oar':1.8,'brush':1.7}[kind]
  m.tube([(0,0,.65),(0,0,-length)],[.045,.042],WOOD,8)
  for z in [.55,-length+.18]: m.tube([(0,0,z-.10),(0,0,z+.10)],[.065,.065],GOLD,8)
  if kind=='long_spear':
   m.blade([(-.035,-2),(-.14,-2.25),(0,-2.85),(.14,-2.25),(.035,-2)],.055,SILVER)
   for i in range(7):
    x=(i-3)*.035;m.ribbon([(x,0,-2),(x+.15,-.06,-1.76),(x+.28,-.17,-1.48)],[.035,.027,.004],RED)
  elif kind=='iron_staff':
   for end in [-1.8,.42]:
    path=[(.072*math.cos(i*TAU/16),.072*math.sin(i*TAU/16),end+i*.025) for i in range(17)]
    m.tube(path,[.018]*len(path),GOLD,4)
  elif kind=='trident':
   m.blade([(-.035,-1.8),(-.12,-2.15),(0,-2.7),(.12,-2.15),(.035,-1.8)],.05,SILVER)
   for side in [-1,1]:
    m.tube([(0,0,-1.7),(side*.23,0,-1.95),(side*.28,0,-2.32)],[.07,.06,.01],SILVER,6)
   m.ribbon([(0,0,-1.65),(.28,.02,-1.4),(.45,-.10,-1.12)],[.07,.04,0],col('427d80'))
  elif kind=='oar':
   m.blade([(-.08,-1.4),(-.32,-1.8),(-.28,-2.45),(.24,-2.4),(.29,-1.8),(.08,-1.4)],.07,col('8f7960'))
   for z in [-1.9,-2.1,-2.3]:m.tube([(-.22,.07,z),(.2,.07,z)],[.012,.012],GOLD,4)
  else:
   m.tube([(0,0,-1.5),(0,0,-1.72),(0,0,-2.15)],[.15,.12,.002],PALE,10)
   m.tube([(0,0,-2),(0,0,-2.18)],[.052,.001],INK,8)
 elif kind=='heavy_cleaver':
  m.tube([(0,0,.28),(0,0,-1.25)],[.06,.06],WOOD,8)
  m.blade([(-.05,-.75),(-.57,-.66),(-.74,-.86),(-.78,-1.2),(-.54,-1.43),(-.04,-1.28),(.22,-1.22),(.3,-.94)],.11,col('aebbb1'),SILVER)
  m.blade([(-.52,-.75),(-.65,-.91),(-.66,-1.17),(-.5,-1.31),(-.40,-1.23),(-.5,-1.08)],.116,GOLD)
 elif kind=='debt_scale':
  m.tube([(0,0,.2),(0,0,-1.25)],[.06,.045],WOOD,8)
  m.tube([(-.6,0,-1.25),(.6,0,-1.25)],[.05,.05],GOLD,6)
  for side in [-1,1]:
   m.tube([(side*.5,0,-1.25),(side*.5,-.4,-1.25)],[.015,.015],GOLD,5)
   pan=Mesh();pan.blade([(side*.5-.22,-1.1),(side*.5-.25,-1.35),(side*.5,-1.5),(side*.5+.25,-1.35),(side*.5+.22,-1.1)],.07,PALE);pan.translate((0,-.4,0));m.p.extend(pan.p);m.n.extend(pan.n);m.c.extend(pan.c)
 elif kind=='wish_scepter':
  m.tube([(0,0,.15),(0,0,-1.25)],[.05,.05],GOLD,8)
  for i in range(5):
   a=i*TAU/5;m.tube([(0,0,-1.18),(.28*math.cos(a),.28*math.sin(a),-1.45),(0,0,-1.63)],[.02,.055,.005],GOLD,6)
  m.ellipsoid((0,0,-1.4),(.12,.12,.12),RED,8,4)
 elif kind=='judge_tablet':
  m.blade([(-.23,.1),(-.27,-.65),(-.18,-.86),(.18,-.86),(.27,-.65),(.23,.1)],.055,PALE)
  for z in [-.1,-.28,-.46,-.64]:m.tube([(-.11,.06,z),(.11,.06,z)],[.013,.013],INK,4)
 else:
  m.tube([(0,0,.23),(0,0,-.27)],[.045,.045],INK,8)
  for z in [.02,.10,.18]:m.tube([(0,0,z-.016),(0,0,z+.016)],[.051,.051],GOLD,8)
  m.tube([(-.23,0,-.22),(0,.02,-.26),(.23,0,-.22)],[.03,.045,.03],GOLD,6)
  if kind=='long_sword':
   m.blade([(-.055,-.26),(-.09,-1.35),(0,-1.70),(.09,-1.35),(.055,-.26)],.038,SILVER)
   m.ribbon([(0,0,.22),(.07,-.12,.42),(.03,-.30,.5)],[.03,.045,.005],col('4f8a83'))
  else:
   m.blade([(-.055,-.26),(-.11,-1.32),(-.03,-1.57),(.23,-1.34),(.25,-.88),(.12,-.25)],.046,SILVER,col('91a69d'))
   m.tube([(.12,.02,-.4),(.19,.02,-.9),(.18,.02,-1.25)],[.022,.022,.014],GOLD,4)
 return m

def ring(m,center,radius,color,n=24,thickness=.025):
 path=[add(center,(math.cos(i*TAU/n)*radius,math.sin(i*TAU/n)*radius,0)) for i in range(n+1)]
 m.tube(path,[thickness]*(n+1),color,5)

def character(kind):
 g=GLB(kind);body=g.node('Body')
 boss=kind.startswith('boss_');player=kind=='player';brute=kind=='brute'
 cloth={'player':'c1c5b5','grunt':'59645b','ranger':'486d77','brute':'544b48','boss_ferry':'4e686b','boss_wish':'a05a63','boss_judge':'38545e','boss_erlang':'547d7b','boss_master':'9e8861','boss_debt':'666f58','dummy':'887450'}[kind]
 cloth=col(cloth);width=1.2 if brute else (.92 if kind=='boss_wish' else 1)
 coat=Mesh();detail=Mesh();cape=Mesh()
 coat.loft([(.32,.34*width,.24,0,.05),(.68,.29*width,.21,0,.02),(.96,.22*width,.18,0,0),(1.27,.30*width,.20,0,0),(1.39,.24*width,.16,0,0)],cloth,12,.10)
 # Open split tails and crossed collar are authored strips, not box ornaments.
 for side in [-1,1]:
  coat.ribbon([(side*.16,.91,-.18),(side*.23,.63,-.24),(side*.31,.23,-.19)],[.12,.14,.10],cloth)
  detail.tube([(side*.21,1.39,-.14),(-side*.04,1.13,-.215),(-side*.12,.99,-.20)],[.023]*3,GOLD,5)
 detail.loft([(.91,.257*width,.21,0,0),(.99,.25*width,.20,0,0)],INK,12)
 detail.ellipsoid((0,.95,-.23),(.105,.065,.028),GOLD,8,4)
 detail.loft([(1.38,.085,.08,0,0),(1.48,.09,.085,0,0)],SKIN,8)
 detail.ellipsoid((0,1.65,-.005),(.195,.235,.178),SKIN if player or kind in ['boss_master','boss_erlang','boss_wish'] else PALE,12,8)
 # Sculpted nose, brows, inset eyes and hair cap.
 detail.tube([(0,1.67,-.17),(0,1.60,-.23),(0,1.58,-.19)],[.035,.035,.02],SKIN,5)
 for side in [-1,1]:
  detail.tube([(side*.035,1.695,-.175),(side*.12,1.70,-.15)],[.013,.017],INK,4)
  detail.ellipsoid((side*.073,1.655,-.17),(.033,.012,.014),GOLD if not player else INK,6,4)
 detail.loft([(1.74,.19,.17,0,.01),(1.86,.15,.13,0,.01),(1.91,.05,.06,0,.02)],INK,12)
 if player:
  detail.loft([(1.83,.63,.56,0,0),(1.88,.58,.51,0,0),(2.08,.08,.07,0,0)],col('9b8e68'),24)
  for i in range(16):
   a=i*TAU/16;detail.tube([(math.cos(a)*.58,1.89,math.sin(a)*.51),(0,2.085,0)],[.007,.004],GOLD,4)
  cape.ribbon([(0,1.37,.2),(.05,1.04,.35),(-.08,.64,.47),(.08,.30,.42)],[.25,.34,.40,.25],RED)
  detail.tube([(-.12,1.48,-.03),(-.18,1.2,-.23),(.25,.96,-.23)],[.035]*3,RED,6)
 elif kind=='grunt':
  detail.loft([(1.70,.23,.20,0,0),(1.85,.3,.26,0,0),(2.0,.04,.05,0,-.02)],col('3f4842'),9)
  detail.ribbon([(0,1.83,-.22),(0,1.56,-.235),(0,1.38,-.23)],[.075,.07,.04],col('d2bb8a'))
  detail.tube([(0,1.77,-.24),(0,1.46,-.25)],[.015,.012],RED,4)
 elif kind=='ranger':
  detail.loft([(1.71,.24,.20,0,.03),(1.93,.26,.20,0,.06),(2.17,.03,.035,0,.16)],INK,8)
  cape.ribbon([(0,1.38,.2),(0,.85,.39),(0,.36,.35)],[.27,.4,.3],cloth)
  for side in [-1,1]:detail.ribbon([(side*.23,1.84,0),(side*.30,1.32,.13),(side*.4,.92,.21)],[.05,.055,.02],PALE)
 elif brute:
  detail.loft([(1.69,.25,.21,0,0),(1.90,.27,.22,0,.03),(2.02,.14,.15,0,.03)],col('8c9c91'),10)
  detail.ellipsoid((0,1.57,-.17),(.22,.17,.07),col('7c8a81'),10,4)
  for side in [-1,1]:detail.tube([(side*.18,1.89,0),(side*.37,2.0,.06),(side*.43,2.13,.11)],[.07,.045,.005],GOLD,6)
  for row in range(3):
   for x in [-.16,0,.16]:detail.ellipsoid((x,1.1+row*.09,-.215),(.095,.067,.035),col('96a69b'),6,4)
 elif kind=='boss_ferry':
  detail.loft([(1.81,.6,.45,0,.06),(1.89,.49,.39,0,.06),(2.01,.08,.07,0,.06)],col('766d54'),16)
  for i in range(3):
   detail.tube([(-.37,1.36,.11),(-.3,1.20,-.23),(.05,1.02,-.29),(.32,.99,.02)],[.035]*4,GOLD,6)
  for i in range(5):
   z=.19+i*.05;detail.tube([(-.35,1.25,z),(0,.5,z+.12),(.4,1.15,z)],[.024]*3,WOOD,5)
  detail.tube([(0,1.55,-.18),(0,1.35,-.24),(0,1.24,-.17)],[.12,.08,.01],col('b9b7a5'),8)
 elif kind=='boss_wish':
  coat.loft([(.12,.64,.40,0,.06),(.58,.42,.29,0,.03),(.99,.22,.18,0,0)],cloth,16,.10)
  ring(detail,(0,1.5,.25),.82,GOLD,32,.025)
  for i in range(9):
   a=i*math.pi/8;detail.tube([(math.cos(a)*.82,1.5+math.sin(a)*.82,.25),(math.cos(a)*1.0,1.5+math.sin(a)*1.0,.25)],[.03,.002],GOLD,5)
  for i in range(5):
   x=(i-2)*.10;detail.tube([(x,1.83,0),(x*1.5,2.04+(.10 if i==2 else 0),0),(x*1.3,2.14,0)],[.055,.032,.002],GOLD,6)
  for side in [-1,1]:cape.ribbon([(side*.28,1.38,.05),(side*.65,1.19,.18),(side*.82,.67,.22)],[.12,.22,.10],col('cf927e'))
 elif kind=='boss_judge':
  detail.loft([(1.8,.28,.22,0,.02),(2.12,.24,.20,0,.02),(2.27,.15,.15,0,.02)],INK,8)
  for side in [-1,1]:detail.tube([(side*.2,2.05,0),(side*.65,2.03,0),(side*.75,2.14,0)],[.055,.04,.012],GOLD,6)
  detail.ellipsoid((0,1.59,-.145),(.19,.19,.075),col('bacfc9'),10,6)
  detail.ribbon([(0,1.78,-.235),(0,1.52,-.24),(0,1.3,-.18)],[.028,.018,.008],INK)
  cape.ribbon([(0,1.38,.2),(0,.85,.42),(0,.14,.32)],[.27,.42,.32],INK)
 elif kind=='boss_debt':
  detail.loft([(1.78,.27,.22,0,0),(2.15,.29,.21,0,.03),(2.22,.22,.17,0,.03)],INK,8)
  for side in [-1,1]:
   detail.tube([(side*.24,1.95,.03),(side*.52,1.88,.04)],[.08,.05],GOLD,6)
  for row in range(4):
   for x in [-.22,-.07,.08,.23]:detail.ellipsoid((x,1.03+row*.11,-.24),(.062,.041,.043),GOLD,5,4)
  for side in [-1,1]:
   cape.ribbon([(side*.24,1.39,.2),(side*.42,.85,.30),(side*.36,.2,.23)],[.12,.17,.11],PALE)
  detail.ribbon([(0,1.80,-.21),(0,1.51,-.22),(0,1.33,-.20)],[.06,.05,.025],RED)
 elif kind=='boss_erlang':
  detail.loft([(1.76,.21,.18,0,0),(1.96,.19,.14,0,0),(2.1,.02,.03,0,0)],SILVER,12)
  for side in [-1,1]:
   detail.tube([(side*.13,1.96,.04),(side*.3,2.35,.1),(side*.46,2.52,.20)],[.045,.025,.002],INK,6)
   detail.ellipsoid((side*.31,1.35,0),(.24,.12,.25),SILVER,10,5)
  detail.ellipsoid((0,1.75,-.177),(.026,.07,.018),GOLD,8,5)
  detail.ellipsoid((0,1.2,-.2),(.27,.21,.075),SILVER,12,6)
  cape.ribbon([(0,1.4,.2),(0,.93,.37),(.1,.2,.42)],[.24,.37,.29],col('4f8491'))
 elif kind=='boss_master':
  detail.ellipsoid((0,1.93,.07),(.105,.11,.10),col('686e62'),10,5)
  detail.tube([(0,1.53,-.17),(0,1.36,-.21),(0,1.18,-.14)],[.1,.055,.001],col('bec2af'),8)
  cape.ribbon([(0,1.34,.2),(0,.93,.28),(0,.35,.25)],[.23,.31,.29],col('746b53'))
 g.node('Cloth',body,mesh=coat);g.node('Details',body,mesh=detail)
 if cape.p:g.node('Cloak',body,mesh=cape)
 limb_nodes=[]
 for side,name in [(-1,'Left'),(1,'Right')]:
  leg=Mesh();leg.loft([(-.52,.12,.19,0,-.05),(-.39,.11,.13,0,0),(-.05,.095,.10,0,0)],INK,8)
  leg.loft([(-.48,.13,.22,0,-.065),(-.34,.12,.16,0,-.03)],WOOD,8)
  l=g.node(name+'Leg',body,(side*.16,.60,0),leg);limb_nodes.append(l)
  arm=Mesh();arm.tube([(0,0,0),(side*.14,-.23,.0),(side*.18,-.45,-.15)],[.16 if boss else .14,.13,.08],cloth,8)
  arm.ellipsoid((side*.18,-.46,-.15),(.085,.105,.085),SKIN,8,5)
  arm.tube([(side*.155,-.33,-.07),(side*.175,-.41,-.12)],[.11,.10],GOLD if brute or kind=='boss_erlang' else INK,8)
  if kind=='boss_master' and side==-1:
   ring(arm,(-.18,-.51,-.15),.09,GOLD,12,.016)
   arm.loft([(-.9,.13,.13,-.18,-.15),(-.61,.12,.12,-.18,-.15)],col('d8b66c'),8)
   for z in [-.26,-.04]:
    for x in [-.29,-.07]:arm.tube([(x,-.91,z),(x,-.60,z)],[.018,.018],WOOD,4)
   arm.loft([(-.95,.04,.04,-.18,-.15),(-.91,.17,.17,-.18,-.15)],GOLD,8)
  a=g.node(name+'Arm',body,(side*.32*width,1.31,0),arm)
  if side==1:
   grip=g.node('Grip',a,(side*.18,-.46,-.15));wn=g.node('Weapon',grip)
   wk={'player':'ferry_blade','grunt':'ferry_blade','ranger':'wish_scepter','brute':'heavy_cleaver','boss_ferry':'oar','boss_wish':'wish_scepter','boss_judge':'judge_tablet','boss_erlang':'trident','boss_master':'brush','boss_debt':'debt_scale','dummy':'iron_staff'}[kind]
   g.node('HeldMesh',wn,mesh=weapon(wk))
 if boss:g.j['nodes'][0]['scale']=[1.68,1.60,1.68]
 elif brute:g.j['nodes'][0]['scale']=[1.25,1.15,1.25]
 g.clip('Walk',[(limb_nodes[0],0,[0,.5,0,-.5,0]),(limb_nodes[1],0,[0,-.5,0,.5,0])])
 g.clip('Attack',[(wn,1,[0,-.8,.7,.15,0])])
 g.clip('Idle',[(body,2,[0,.012,0,-.012,0])])
 return g

if __name__=='__main__':
 report=[]
 for kind in ['player','grunt','ranger','brute','boss_ferry','boss_wish','boss_judge','boss_erlang','boss_master','boss_debt','dummy']:
  report.append(character(kind).save(kind))
 for kind in ['ferry_blade','long_sword','long_spear','iron_staff','heavy_cleaver','oar','wish_scepter','judge_tablet','trident','brush','debt_scale']:
  g=GLB(kind);g.node('BladeMesh',mesh=weapon(kind));report.append(g.save(kind))
 (OUT/'inventory.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
 for row in report:print(row['file'],row['triangles'],'triangles',row['mesh_parts'],'parts')
