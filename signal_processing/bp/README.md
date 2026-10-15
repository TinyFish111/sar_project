# 条带斜视BP入口

```matlab
addpath('D:/sar_project/common/io','D:/sar_project/signal_processing/bp');
xy_m = [0,28284.271247]; % 每行一个待成像地面像素，列为x/y，单位m
result = run_bp_squint('已有echo.mat路径',xy_m,4);
```

只读取实际echo样本。按脉冲块距离压缩、4倍带限加密、四点Lagrange取样；精确欧氏斜距逐像素相干累加，按固定波束判据限制照射。
距离滤波沿用旧实现的解析LFM频域匹配相位及矩形带限，属于有限时宽LFM的近似匹配。与连续有限LFM自相关PSF作独立检查，并用8倍距离加密检查数值收敛。
传播几何未作二次展开，但仍有采样、插值、波形匹配及stop-go模型的限制，不称作无条件精确真值。

result.values与xy_m逐行对应，保存复数值和耗时。确定性相位屏使用孔径中心平台位置到每个像素的斜距；result.parameters.phase_screen_range_m可用于恢复该相位。
独立解析PSF只在common/metrics作为验证，不是BP输入，也不被BP调用。
