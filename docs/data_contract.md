# 回波与成像数据约定（1.0）

首次实现为机载正侧视点目标，字段由 generate_echo.m 和 run_rd.m 明确定义。

echo.mat包含一个dataset结构体：
- schema_version：格式版本。
- id：唯一回波编号。
- echo：复数矩阵，慢时间×快时间。
- fast_time_s、slow_time_s：秒为单位的采样坐标。
- radar：载频Hz、带宽Hz、脉宽s、调频率Hz/s、采样率Hz、PRF Hz及波形说明。
- geometry：平台轨迹、坐标系、单位、几何模型、斜视角定义。
- targets：目标位置、散射系数及坐标系。
- processing_state：原始基带、距离压缩后等明确状态。
- configuration：完整生成配置，以SI单位存储，含用户表格的参考派生值。
- truth：点目标精确斜距历程、中心方位调频率、有效孔径长度及派生多普勒带宽。
- provenance：配置路径、生成时Git版本、未提交修改状态、随机种子、生成时间、MATLAB版本。

算法输出包括复数 image、slant_range_m、along_track_m、输入回波编号、处理参数、耗时及diagnostics。
PSLR/ISLR使用复数切片interpft插值、峰值两侧首个局部极小值划分主瓣；ISLR积分限于记录的切片窗口。
IRW为功率半高（-3.0103dB）宽度。无加窗；不能把理论矩形窗ISLR约-9.68dB误认作计算失败。
