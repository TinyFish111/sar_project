# 本次实测边界

运行：run_20261015_squint_boundary。实际角网格：[0 1 2 3 4 5 6 7 8 9 10 15 20 25 30 35 40 45 50 55 60 65 70] deg。三种距离位置分别激励，另验证三方位位置的平移协变。

固定最近斜距30km、10km最近斜距带、1km方位测试段、1m有效天线矩形角域照射，平地stop-go理想回波。

判据：两向IRW与同角同位置参照相差<=15%；PSLR/ISLR恶化<=2dB；定位误差<=0.5个参照分辨率单元。BP另对连续有限LFM解析PSF校验。

| 方法 | 最大连续已测合格角 / deg | 首次不合格角 / deg | 解释 |
|---|---:|---:|---|
| RD | 8 | 9 | 本场景及本实现的经验边界 |
| CS | 8 | 9 | 本场景及本实现的经验边界 |
| WK | 70 | 未观察到 | 已验证至70deg，尚未找到上限 |
| BP | 70 | 未观察到 | 已验证至70deg，尚未找到上限 |

边界由所有探测点共同决定。中心点可能在更高角度通过，且某些指标随角度非单调；详见angle_summary.csv和boundary_and_sensitivity.csv。

各判据单独首次失败的区间见criterion_failure_brackets.csv：旁瓣不合格不等于完全无法形成主瓣。未经另外细化的区间仍按实际角网格报告。

1dB/3dB旁瓣容差只作阈值敏感性分析，未在其每个首次失败区间另行全部细化。不能将离散网格上的首次失败当作严格解析角度极限。

## 数值与复现核查

- BP距离插值加密与几何平移：9项，全部通过=1（numerical_validation.csv）。
- 70deg最远距WK抽头及网格加密：1项，全部通过=1（wk_numerical_validation.csv）。
- 首次边界Fr从120到240MHz：2项，全部通过=1（boundary_sampling_validation.csv）。
- 独立平移回波的四法处理：4项，全部通过=1（translated_processing_validation.csv）。
- 最终源文件低角度复现：6项，全部通过=1（final_source_reproduction.csv）。

PSF主瓣检验：BP相对连续有限LFM解析参照的最大宽度差异为0.774%。BP采用解析带限LFM匹配，相比有限时宽信号仍有小的模型/匹配差异。

原始数据：data/simulated/echo_002_*_run_20261015_squint_boundary/echo.mat。复数局部图与剖面：results/exp_002_airborne_squint_boundary/run_20261015_squint_boundary/<方法>/。各方法图片在其figures/，跨方法汇总在运行目录figures/。

本实验不包括分布式强弱目标串扰、真实天线电子扫描损失、运动误差、噪声、地球曲率或连续全幅聚焦证明。代码版本见source_manifest.json及completion.md。
