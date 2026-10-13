# 回波001：典型机载参数、单点、正侧视

生成日期：2026-10-13 18:55:34（Asia/Shanghai）。
目的：作为RD基础聚焦实验输入；不用于验证星载、大斜视或真实天线辐射性能。
完整参数见experiments/exp_001_airborne_rd/records/run_20261013_185533_990/generation_config.json。

- 回波编号：echo_001_airborne_single_broadside_20261013_185533_990。
- 生成入口：echo_generation/generate_echo.m。
- 配置：echo_generation/configs/airborne_point_baseline.m。
- 精确几何：匀速250m/s直线、平台高度10km、中心斜距30km、平面静止目标。
- 目标：航迹方向0m、横航迹sqrt(30000^2-10000^2)m、地面高度0m，复散射系数1。
- 波形：9.4GHz载频，10us LFM，调频率1e13Hz/s，带宽100MHz；原始复基带。
- 距离采样率120MHz，PRF600Hz，3.4s矩形照射，0度斜视。
- 快时间列数9686，慢时间行数2040，single复数。
- 有效斜距带25至35km；采样窗口额外覆盖脉宽和2us保护。
- 随机种子记录为1，本例无噪声，因此没有随机散射。
- 距离徙动最大3.010266m，中心方位调频率-130.645937Hz/s，派生多普勒带宽444.196187Hz。
- 本地路径：data/simulated/echo_001_airborne_single_broadside_20261013_185533_990/echo.mat。
- 生成时提交1754d7e且工作区dirty；本次源文件指纹见对应实验source_manifest.json，最终实现版本见completion.md。
- 数据检查：尺寸、有限性、时间采样、完整脉冲支持及基本几何通过；成像结果见实验001。

回波矩阵和平台逐脉冲轨迹保存在本地MAT中，不上传GitHub。公开记录只保留本次人工仿真参数与指标。
