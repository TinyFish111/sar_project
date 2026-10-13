# SAR成像配色与显示规范

用户于2026-10-13要求：今后仿真成像的结果配色，以此前五算法统一参数仿真的图片为例。

## 参考来源与核查
参考目录（仅用于追溯，不作为新代码的运行依赖）：
`C:\Users\29344\Desktop\class matierial\class matierial\本科\毕设\实验代码\五算法统一参数仿真\results`

该目录含RD、CS、WK、BP、FBP在0度及8度斜视下的成像图片。
已查看代表图img_RD_airborne_squint0.png、img_CS_airborne_squint0.png、img_BP_airborne_squint8.png。
同时检查相邻run_all.m的绘图代码，确认实际使用 `colormap(gca,parula)`、成像色标[-40,0]、剖面范围[-45,2]。
据此确定下列默认设置，避免仅凭图像颜色猜测色图。

## 全项目默认要求
1. SAR成像幅度图、全场景图、局部放大图使用MATLAB `parula(256)`。低幅度呈深蓝/紫蓝色，高幅度呈黄色。默认不使用turbo、jet或灰度替代。
2. 成像图使用相对峰值归一化幅度dB：`20*log10(abs(image)/max(abs(image(:))))`，色标固定为[-40,0] dB，并显示colorbar。
3. 数值上对零幅度和色标下限做保护，不修改原始复数图像。显示截断不参与指标计算。
4. 距离/方位单曲线剖面统一使用蓝色RGB [0,0.4470,0.7410]、线宽1.2、白色背景和网格；默认纵轴[-45,2] dB。
5. 同组算法或参数对比使用相同色图、色标和归一化说明。单图峰值归一化会隐藏绝对幅度差异；若要比较能量或增益，另行采用共同参考并注明。
6. 图像坐标使用 `axis xy`，标清实际坐标类型和单位。参考图是方位x/地距y；当前RD基线采用最近斜距和方位坐标，不能为了外观一致把斜距误写为地距。
7. 本要求固定配色和显示口径，不强制照搬参考图的四宫格布局、场景范围、目标数量或插值倍数。
8. 线性幅度原始回波等诊断图也默认使用parula，但保留其线性幅度色标并明确标注，不能强制写成归一化成像dB。
9. 特殊实验确需其他动态范围或配色时，在实验配置与记录中明确原因；同一比较组统一采用该例外设置。

## 实现位置
公共样式入口：`common/plotting/sar_plot_style.m`。
现有 `plot_airborne_rd_experiment.m` 已接入该样式；RD配置中的默认db_floor已改为-40。
新增方法和实验绘图应复用该入口，不在不同算法文件夹分别定义一套配色。

## 最小示例（MATLAB R2021b兼容）
```matlab
style = sar_plot_style();
amplitude = abs(image);
relative_db = 20*log10(max(amplitude/max(amplitude(:)),10^(style.image_db_limits(1)/20)));
imagesc(range_m,azimuth_m,relative_db);
axis xy;
colormap(gca,parula(style.colormap_size));
caxis(style.image_db_limits); % 用caxis兼容R2021b
colorbar;
```

历史实验图片保留，不覆盖。样式更新后的重绘保存到新的预览目录；没有重新生成回波或运行成像算法。
