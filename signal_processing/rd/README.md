# 正侧视RD基线

## 独立使用
此方法只接收回波数据，不生成回波，也不依赖其他成像算法。

```matlab
project_root = 'D:/sar_project';
addpath(fullfile(project_root,'signal_processing','rd'));
loaded = load('你的echo.mat绝对路径','dataset');
result = run_rd(loaded.dataset, rd_baseline_config());
```

`dataset`使用项目数据约定。输出复数图像、最近斜距与方位坐标、耗时和诊断信息。

## 处理步骤与符号
采用 exp(-j*4*pi*R/lambda) 的回波传播相位。
1. 对有限长发射LFM参考信号作共轭时间反转，补零实现线性距离卷积，补偿参考滤波器群延迟。
2. 双边补零并沿慢时间FFT。矩阵行为方位，列为距离。
3. 定义 D(fa)=sqrt(1-(lambda*fa/(2*v))^2)。将当前频率行中 R/D(fa) 的回波插值到最近斜距 R。
4. 用 exp(+j*4*pi*R/lambda*(D(fa)-1)) 补偿双曲方位相位。常量距离相位保留，故图像仍是复数。
5. 方位IFFT获得成像。完整10km斜距带参与处理，保存中心ROI复数图与全场景幅度缩略图。

RCMC采用16点Lanczos截断sinc，权重归一化。不加窗。

## 当前边界
正侧视、匀速直线航迹、平面静止点目标、stop-go假设。不支持任意斜视与曲线轨迹。
未实施二次距离压缩SRC、运动补偿、自聚焦、传播衰减和噪声。本例高载频/相对窄带且正侧视，应以实际IRW和旁瓣检查验证近似，不外推到大斜视。
未调用MATLAB内置rangeDopplerImagerLFM：该函数从R2022a引入，用户环境为R2021b。
参考：https://www.mathworks.com/help/phased/ref/rangedopplerimagerlfm.html

## 实验002的斜视RD+SRC入口

保留上面的正侧视基线，新增run_rd_squint。按实验002的meta+echo格式读取数据，公共I/O仅准备去多普勒中心后的方位频谱，RD不依赖CS、WK或BP。

```matlab
addpath('D:/sar_project/common/io','D:/sar_project/signal_processing/rd');
cache = prepare_squint_spectrum('已有echo.mat路径','D:/sar_project/scratch/my_rd_spectrum.mat');
result = run_rd_squint(cache);
```

距离压缩含固定30km参考的二阶SRC，RCMC按各输出距离的R/D轨迹重采样；8倍距离加密。
中心方位参考使用精确历程的相位部分，并补标准距离相关差分相位。输出坐标及去载波状态见docs/data_contract.md 2.0。
参考SRC误差和更高阶耦合保留用于测边界；不加入新的高阶空间变化算法。只支持本文直线条带模型。
