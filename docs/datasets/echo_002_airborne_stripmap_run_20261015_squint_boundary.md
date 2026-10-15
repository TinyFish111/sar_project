# 机载条带大斜视独立点目标回波集合

运行编号：run_20261015_squint_boundary。

正式扫描含23种角度、69种角度/距离工况，每工况四法共用一份实际LFM回波；另有独立x=500m平移检查及首次边界Fr加倍检查。集合共71份MAT原始数据。

固定最近斜距中心30km、最近斜距范围25至35km，固定地面场景y=sqrt(r^2-H^2)。方位测试位置-500/0/500m；主数据分别激励近/中/远点，其他方位位置利用条带平移协变并经数值检查。不是同时九点的完整分布式场景数据。

H=10km，v=250m/s，f0=9.4GHz，B=100MHz，Tr=10us，Kr=1e13Hz/s，Fr=120MHz，1m有效方位天线。理想固定角宽矩形照射，无噪声、无衰减、平地、匀速、stop-go。PRF按完整二维谱支撑加余量重算；快慢时间窗按逐点几何重算。

echo矩阵行慢时间、列快时间，复数single；meta保存秒制采样轴、雷达、平台轨迹、目标、配置、照射区间、生成HEAD/dirty状态与检查。格式2.0/2.1的配置别名差异见[数据约定](../data_contract.md)，实际波形模型一致，旧数据不覆盖。

2.0中的实际照射时间与瞬时斜距应读取geometry.entry_exit_s/slant_range_m与checks，不读取继承的正侧视3.4s/30km别名。统一几何摘要见实验记录sampling_geometry_checks.csv。

检查：生成块有限、脉冲完整入窗；首/中/末脉冲复样本与所记几何一致；全幅PRI兼容性；独立解析PSF、BP/WK数值加密、平移处理和最终源文件复现。实际通过状态见实验记录各validation.csv。

指标和结论：[实验记录](../../experiments/exp_002_airborne_squint_boundary/records/run_20261015_squint_boundary/conclusions.md)。最终实现提交号见同目录completion.md；生成时的旧HEAD且dirty=true不代表最终代码版本。

| 回波编号 | 角度 / deg | 最近斜距 / km | 方位位置 / m | Fr / MHz | 格式 |
|---|---:|---:|---:|---:|---|
| echo_002_fr240_sq09_r25000_run_20261015_squint_boundary | 9 | 25 | 0 | 240 | 2.1_stripmap_probe |
| echo_002_shift500_sq08_run_20261015_squint_boundary | 8 | 30 | 500 | 120 | 2.1_stripmap_probe |
| echo_002_sq00_r25000_run_20261015_squint_boundary | 0 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq00_r30000_run_20261015_squint_boundary | 0 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq00_r35000_run_20261015_squint_boundary | 0 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq01_r25000_run_20261015_squint_boundary | 1 | 25 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq01_r30000_run_20261015_squint_boundary | 1 | 30 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq01_r35000_run_20261015_squint_boundary | 1 | 35 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq02_r25000_run_20261015_squint_boundary | 2 | 25 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq02_r30000_run_20261015_squint_boundary | 2 | 30 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq02_r35000_run_20261015_squint_boundary | 2 | 35 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq03_r25000_run_20261015_squint_boundary | 3 | 25 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq03_r30000_run_20261015_squint_boundary | 3 | 30 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq03_r35000_run_20261015_squint_boundary | 3 | 35 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq04_r25000_run_20261015_squint_boundary | 4 | 25 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq04_r30000_run_20261015_squint_boundary | 4 | 30 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq04_r35000_run_20261015_squint_boundary | 4 | 35 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq05_r25000_run_20261015_squint_boundary | 5 | 25 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq05_r30000_run_20261015_squint_boundary | 5 | 30 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq05_r35000_run_20261015_squint_boundary | 5 | 35 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq06_r25000_run_20261015_squint_boundary | 6 | 25 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq06_r30000_run_20261015_squint_boundary | 6 | 30 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq06_r35000_run_20261015_squint_boundary | 6 | 35 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq07_r25000_run_20261015_squint_boundary | 7 | 25 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq07_r30000_run_20261015_squint_boundary | 7 | 30 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq07_r35000_run_20261015_squint_boundary | 7 | 35 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq08_r25000_run_20261015_squint_boundary | 8 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq08_r30000_run_20261015_squint_boundary | 8 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq08_r35000_run_20261015_squint_boundary | 8 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq09_r25000_run_20261015_squint_boundary | 9 | 25 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq09_r30000_run_20261015_squint_boundary | 9 | 30 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq09_r35000_run_20261015_squint_boundary | 9 | 35 | 0 | 120 | 2.1_stripmap_probe |
| echo_002_sq10_r25000_run_20261015_squint_boundary | 10 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq10_r30000_run_20261015_squint_boundary | 10 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq10_r35000_run_20261015_squint_boundary | 10 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq15_r25000_run_20261015_squint_boundary | 15 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq15_r30000_run_20261015_squint_boundary | 15 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq15_r35000_run_20261015_squint_boundary | 15 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq20_r25000_run_20261015_squint_boundary | 20 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq20_r30000_run_20261015_squint_boundary | 20 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq20_r35000_run_20261015_squint_boundary | 20 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq25_r25000_run_20261015_squint_boundary | 25 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq25_r30000_run_20261015_squint_boundary | 25 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq25_r35000_run_20261015_squint_boundary | 25 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq30_r25000_run_20261015_squint_boundary | 30 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq30_r30000_run_20261015_squint_boundary | 30 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq30_r35000_run_20261015_squint_boundary | 30 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq35_r25000_run_20261015_squint_boundary | 35 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq35_r30000_run_20261015_squint_boundary | 35 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq35_r35000_run_20261015_squint_boundary | 35 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq40_r25000_run_20261015_squint_boundary | 40 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq40_r30000_run_20261015_squint_boundary | 40 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq40_r35000_run_20261015_squint_boundary | 40 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq45_r25000_run_20261015_squint_boundary | 45 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq45_r30000_run_20261015_squint_boundary | 45 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq45_r35000_run_20261015_squint_boundary | 45 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq50_r25000_run_20261015_squint_boundary | 50 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq50_r30000_run_20261015_squint_boundary | 50 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq50_r35000_run_20261015_squint_boundary | 50 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq55_r25000_run_20261015_squint_boundary | 55 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq55_r30000_run_20261015_squint_boundary | 55 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq55_r35000_run_20261015_squint_boundary | 55 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq60_r25000_run_20261015_squint_boundary | 60 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq60_r30000_run_20261015_squint_boundary | 60 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq60_r35000_run_20261015_squint_boundary | 60 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq65_r25000_run_20261015_squint_boundary | 65 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq65_r30000_run_20261015_squint_boundary | 65 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq65_r35000_run_20261015_squint_boundary | 65 | 35 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq70_r25000_run_20261015_squint_boundary | 70 | 25 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq70_r30000_run_20261015_squint_boundary | 70 | 30 | 0 | 120 | 2.0_stripmap_probe |
| echo_002_sq70_r35000_run_20261015_squint_boundary | 70 | 35 | 0 | 120 | 2.0_stripmap_probe |

本地数据路径为data/simulated/<回波编号>/echo.mat；GitHub只保存代码、参数说明与小型文本指标，不上传MAT和成像产物。
