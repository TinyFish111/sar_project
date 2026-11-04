# 独立星载CS教学实现

入口`run_spaceborne_cs(dataset,spaceborne_cs_options())`只处理`3.0_spaceborne_cs_teaching`格式的原始回波，不调用生成器，不读取`targets`或`truth`；不改动既有机载CS实现。

输入矩阵行为慢时间，列为快时间；参数和距离—速度标定随dataset提供。使用已知真实多普勒中心去中心，并以真实fa=fb+fdc计算D和Km。H1/H2采用三个局部参考距离，H3按输出距离更新Vr。输出Dref=1，共用最近斜距轴，无RCMC或拼接插值。速度标定表查询使用interp1，评价插值与成像分离。

详细公式、相位符号、数组尺寸、参数来源、实际结果及边界见`docs/derivations/spaceborne_cs_teaching/星载斜视SAR的CS算法图解与MATLAB实验.md`。代码采用R2021b兼容语法；实际MATLAB运行版本R2022b。

```matlab
addpath('D:/sar_project/experiments/exp_003_spaceborne_cs_teaching'); % 添加本实验入口及评价绘图函数。
summary = run_imaging('已有echo.mat的绝对路径'); % 只读已有数据，不生成或覆盖原始回波。
```

适用边界：等效双曲模型、常时间而距离空变的Vr、5°教学斜视、窄相对带宽和短有效孔径。有限孔径驻相、距离频率二阶截断及局部Km仍是近似；复数分段接缝和大斜视需另行验证。
