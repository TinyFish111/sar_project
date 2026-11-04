"""生成CS教材的解释图，并复制MATLAB实际结果；示意图与实验图明确区分。"""
from pathlib import Path
import shutil
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'docs/derivations/spaceborne_cs_teaching/figures'
OUT.mkdir(parents=True,exist_ok=True)
plt.rcParams.update({'font.family':'Microsoft YaHei','font.size':11,'axes.unicode_minus':False,'axes.spines.top':False,'axes.spines.right':False,'lines.linewidth':1.2,'figure.facecolor':'white'})
blue='#0072bd'; orange='#d95319'; green='#338166'

def save(fig,name):
    fig.savefig(OUT/name,dpi=180,bbox_inches='tight',facecolor='white')
    plt.close(fig)

def box(ax,x,y,w,h,text,color=blue,size=11):
    patch=FancyBboxPatch((x,y),w,h,boxstyle='round,pad=0.015',ec=color,fc='#edf5fa',lw=1.2)
    ax.add_patch(patch); ax.text(x+w/2,y+h/2,text,ha='center',va='center',fontsize=size,color='#163c55')

def arrow(ax,start,end):
    ax.add_patch(FancyArrowPatch(start,end,arrowstyle='-|>',mutation_scale=14,color='#48677e',lw=1.2))

fig,ax=plt.subplots(figsize=(10,4.8)); ax.set(xlim=(0,1),ylim=(0,1)); ax.axis('off')
items=[('原始回波\n一行一个脉冲',(0.02,.69)),('方位 FFT\n时间换成频率',(.35,.69)),('乘 H1\n统一差动迁移',(.68,.69)),('距离 FFT\n进入二维频域',(.68,.36)),('乘 H2\n压缩脉冲＋平移',(.35,.36)),('距离 IFFT\n回到混合域',(.02,.36)),('乘 H3\n补相位＋聚焦',(.02,.03)),('方位 IFFT\n得到复数图像',(.35,.03)),('检查轨迹、位置\n主瓣和旁瓣',(.68,.03))]
for text,(x,y) in items: box(ax,x,y,.28,.22,text)
for p,q in [((.30,.8),(.35,.8)),((.63,.8),(.68,.8)),((.82,.69),(.82,.58)),((.68,.47),(.63,.47)),((.35,.47),(.30,.47)),((.16,.36),(.16,.25)),((.30,.14),(.35,.14)),((.63,.14),(.68,.14))]: arrow(ax,p,q)
save(fig,'01_处理路线.png')

c=299792458.; fc=5.3e9; r=850000.; v=7037.997681619272; theta=np.deg2rad(5); delta=r*np.tan(theta)/v
eta=np.linspace(-.8,delta+1,600); distance=np.sqrt(r*r+v*v*(eta-delta)**2)
fig,axs=plt.subplots(1,2,figsize=(10,3.8))
axs[0].plot(eta,(distance-r)/1000,color=blue); axs[0].scatter([0,delta],[(r/np.cos(theta)-r)/1000,0],color=[orange,green],zorder=3)
axs[0].annotate('波束中心 η=0\n距离还在减小',(0,(r/np.cos(theta)-r)/1000),xytext=(2.2,2.5),arrowprops={'arrowstyle':'->','color':orange})
axs[0].annotate('最近距离时刻 ηmin\n此时 R=r',(delta,0),xytext=(3.8,.7),arrowprops={'arrowstyle':'->','color':green})
axs[0].axvspan(-.3,.3,color=blue,alpha=.13,label='本实验照射区间')
axs[0].set(xlabel='慢时间 η（s）',ylabel='斜距超过最近距离的部分（km）',title='斜视：零时刻并不是距离最低点'); axs[0].legend(fontsize=9); axs[0].grid(alpha=.25)
axs[1].plot(eta, -2*v*v*(eta-delta)/(c/fc*distance),color=blue)
axs[1].axhline(2*v*np.sin(theta)*fc/c,color=orange,ls='--',label='零时刻真实多普勒中心')
axs[1].set(xlabel='慢时间 η（s）',ylabel='真实多普勒频率（Hz）',title='接近时斜距减小，多普勒为正'); axs[1].legend(fontsize=9); axs[1].grid(alpha=.25)
fig.tight_layout(); save(fig,'02_斜视时间原点.png')

fig,axs=plt.subplots(1,3,figsize=(10,3))
time=np.linspace(-1.5,1.5,800); pulse=(abs(time)<=1)*np.exp(1j*18*np.pi*time**2)
axs[0].plot(time,pulse.real,color=blue); axs[0].plot(time,abs(pulse),ls='--',color=orange); axs[0].set(title='长脉冲：振荡速度逐渐变化',xlabel='相对快时间（示意）',ylabel='实部及包络')
freq=np.linspace(-1,1,800); phase=-6*np.pi*freq**2
axs[1].plot(freq,phase,color=blue,label='信号频谱二次相位'); axs[1].plot(freq,-phase,color=orange,ls='--',label='匹配滤波器相位'); axs[1].legend(fontsize=8); axs[1].set(title='把二次相位逐项抵消',xlabel='距离频率（示意）',ylabel='相位（rad）')
axs[2].plot(time,np.abs(np.sinc(9*time)),color=blue); axs[2].set(title='许多频率在同一位置相加',xlabel='相对延时（示意）',ylabel='压缩后幅度')
for ax in axs: ax.grid(alpha=.2)
fig.tight_layout();save(fig,'03_距离压缩直觉.png')

fb=np.linspace(-650,650,400); fa=fb+2*v*np.sin(theta)*fc/c; d=np.sqrt(1-(c*fa/(2*v*fc))**2); dc=np.sqrt(1-(c*(fa-fb)/(2*v*fc))**2)
fig,axs=plt.subplots(1,2,figsize=(10,3.5))
axs[0].plot(fb,r*(1/d-1),color=blue,label='正确：使用 fa=fb+fdc'); axs[0].plot(fb,r*(1/np.sqrt(1-(c*fb/(2*v*fc))**2)-1),ls='--',color=orange,label='错误：直接把 fb 代入 D')
axs[0].set(title='去中心频率不是物理多普勒频率',xlabel='去中心方位频率 fb（Hz）',ylabel='相对最近斜距的迁移（m）'); axs[0].legend(fontsize=8)
band=np.linspace(-7.754145e6,7.754145e6,400); beta=c*fa[-1]/(2*v); D=d[-1]
linear=4*np.pi*r/c*band/D; quadratic=-2*np.pi*r*beta**2/(c*fc**3*D**3)*band**2
axs[1].plot(band/1e6,quadratic,color=blue); axs[1].set(title='线性项定位，二次项改变压缩形状',xlabel='距离频率（MHz）',ylabel='几何二次相位（rad）')
for ax in axs: ax.grid(alpha=.2)
fig.tight_layout(); save(fig,'04_真实频率与耦合.png')

fig,axs=plt.subplots(1,3,figsize=(10,3.4)); rr=r
for ri,color in [(800000,blue),(850000,orange),(900000,green)]:
    before=2*ri/(c*d); tref=2*rr/(c*d); a=1/d-1
    after1=(before+a*tref)/(1+a)
    shift=2*rr/c*(1/d-1)
    for ax,curve in zip(axs,[before,after1,after1-shift]):
        displacement=(curve-2*ri/c)*c/2
        displacement[np.abs(displacement)<1e-6]=0
        ax.plot(fb,displacement,color=color,label=f'r={ri/1000:.0f} km')
for ax,title in zip(axs,['H1之前：各目标迁移量不同','H1之后：只剩共同的迁移','H2平移后：全部回到各自位置']):
    ax.set(title=title,xlabel='去中心方位频率（Hz）',ylabel='相对各自最近斜距的偏移（m）'); ax.grid(alpha=.2)
axs[0].legend(fontsize=8); fig.tight_layout();save(fig,'05_CS怎样拉齐轨迹.png')

fig,axs=plt.subplots(1,2,figsize=(10,3.4)); t=np.linspace(-2,2,500)
axs[0].plot(t,t*t,color=blue,label='原相位 (τ−τr)²'); axs[0].plot(t,.5*(t-.9)**2,color=orange,label='新增相位 a(τ−τ0)²'); axs[0].plot(t,1.5*(t-.3)**2+.27,color=green,ls='--',label='配方后的同一个和'); axs[0].legend(fontsize=8); axs[0].set(title='配方：找到相加后抛物线的中心',xlabel='快时间（示意）',ylabel='相位除以 πKm（示意）')
f=np.linspace(-1,1,501); delta_tau=.6
axs[1].plot(f,-2*np.pi*f*delta_tau,color=blue,label='原延时相位'); axs[1].plot(f,2*np.pi*f*delta_tau,color=orange,ls='--',label='提前到零点的滤波相位'); axs[1].legend(fontsize=8); axs[1].set(title='线性频率相位：只移动，不改变脉冲形状',xlabel='距离频率（示意）',ylabel='相位（rad）')
for ax in axs: ax.grid(alpha=.2)
fig.tight_layout();save(fig,'06_配方与平移.png')

fig,ax=plt.subplots(figsize=(10,3.7)); ax.axis('off'); ax.set(xlim=(0,1),ylim=(0,1))
for x,text in [(.03,'H1\n混合域乘二次相位\n把差动迁移改成共同偏移'),(.36,'H2\n二维频域压缩并平移\n目标回到各自最近斜距'),(.69,'H3\n混合域去剩余相位\n补偿不同方位频率的相位')]: box(ax,x,.25,.28,.52,text,size=11)
arrow(ax,(.31,.51),(.36,.51)); arrow(ax,(.64,.51),(.69,.51))
ax.text(.5,.09,'每次只抵消有明确来源的相位；目标的位置和散射信息继续保留。',ha='center',color='#163c55')
save(fig,'07_三个滤波器分工.png')

fig,axs=plt.subplots(1,2,figsize=(10,3.6)); rg=np.linspace(847700,852300,500); rs=7156000.; earth=6371000.; mu=3.986004418e14
vr=np.sqrt(mu*(rs*rs+earth*earth-rg*rg)/(2*rs**3))
axs[0].plot((rg-r)/1000,vr,color=blue); axs[0].set(title='每个目标沿时间恒定，跨距离仍变化',xlabel='最近斜距偏移（km）',ylabel='等效速度 Vr（m/s）'); axs[0].grid(alpha=.2)
axs[1].plot((rg-r)/1000,vr,color='#aaaaaa',label='标定曲线')
for lo,hi,center,color in [(-2300,-800,-1600,blue),(-800,800,0,orange),(800,2300,1600,green)]:
    val=np.sqrt(mu*(rs*rs+earth*earth-(r+center)**2)/(2*rs**3)); axs[1].plot([lo/1000,hi/1000],[val,val],color=color,lw=2,label=f'参考偏移 {center:.0f} m')
axs[1].set(title='各距离段用局部参考；方位匹配逐距离更新',xlabel='最近斜距偏移（km）',ylabel='参考速度（m/s）'); axs[1].legend(fontsize=8); axs[1].grid(alpha=.2)
fig.tight_layout();save(fig,'08_距离空变与分段.png')

fig,ax=plt.subplots(figsize=(10,3.2)); ax.axis('off'); ax.set(xlim=(0,1),ylim=(0,1))
box(ax,.02,.3,.28,.45,'生成模块\n雷达＋几何＋目标\n只保存原始 echo.mat')
box(ax,.37,.3,.25,.45,'成像模块\n只读 echo.mat\nH1 → H2 → H3')
box(ax,.69,.3,.28,.45,'评价与绘图\n此处才读取目标真值\n检查轨迹、位置、剖面')
arrow(ax,(.30,.52),(.37,.52)); arrow(ax,(.62,.52),(.69,.52)); ax.text(.5,.11,'回波不调用成像算法；成像器不读取 targets 或 truth。',ha='center',color='#163c55')
save(fig,'09_生成处理与评价独立.png')

fig,ax=plt.subplots(figsize=(10,3.6)); ax.axis('off'); ax.set(xlim=(0,1),ylim=(0,1))
for y,text in [(.72,'几何层：用等效双曲线代替真实轨道距离；本实验不验证轨道级误差'),(.43,'频谱层：驻相近似、距离频率二阶展开、每个距离段采用参考 Km'),(.14,'数值层：有限孔径、有限采样、补零、复数 single 与剖面插值')]: box(ax,.04,y,.92,.18,text,size=11)
save(fig,'10_误差层次.png')

SOURCE=ROOT/'results/exp_003_spaceborne_cs_teaching/run_20261104_223510_663/cs'
for source,target in [('scene_1_RCM校正.png','11_MATLAB单点RCM.png'),('scene_9_成像.png','12_MATLAB九点成像.png'),('scene_1_剖面.png','13_MATLAB单点剖面.png'),('scene_9_剖面.png','14_MATLAB九点剖面.png')]:
    shutil.copy2(SOURCE/source,OUT/target)
print(f'已保存{len(list(OUT.glob("*.png")))}幅图，其中4幅来自实际MATLAB结果。')
