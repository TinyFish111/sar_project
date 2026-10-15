# 实验完成与最终实现版本绑定

实验：exp_002_airborne_squint_boundary。
运行：run_20261015_squint_boundary。
完成日期：2026-10-15，Asia/Shanghai。

## 最终代码版本

最终算法、生成配置、验证入口和可复现实验记录提交：

`4c6e8e088fe1527b7e89ed2e8f638b4bf073b931`

[GitHub实现提交](https://github.com/TinyFish111/sar_project/commit/4c6e8e088fe1527b7e89ed2e8f638b4bf073b931)。2026-10-15 17:59（+08:00）已成功推送既有origin/main。
本文件是在该实现提交完成后追加的版本绑定说明，本文件自身的提交可由Git历史查询；它不改变算法和生成配置。

回波生成时记录的HEAD为`567ae966eb0857b33885c020f80f07d99f0e60ca`且dirty=true；该旧HEAD**不代表本实验的最终实现**。
source_manifest.json记录最终52个MATLAB源文件的SHA-256；source_hash_verification.json记录PowerShell独立复核结果，差异为0。
历史2.0回波的未使用基线配置别名与2.1清理规则已在docs/data_contract.md说明；原始回波不覆盖。实际轨迹、照射和采样始终以所存几何及检查字段为准。

## 已完成内容与门禁

- 23个角度（0:1:10、15:5:70deg）、69种角度/最近斜距工况，四法每工况共用一份实际原始LFM回波。
- 另生成首次边界Fr=240MHz检查回波和x=500m平移检查回波；共71份原始数据。
- 276条独立处理指标；沿航迹平移等价的九位置表为828条，不能将它宣称为九份独立随机试验或同时九点全幅回波。
- 逐份核查71个MAT的矩阵尺寸、采样间隔、轨迹速度、几何距离、脉冲入窗，以及首/中/末照射脉冲的实际复样本。
- 全场景接收窗/最远回波与PRI兼容性通过。
- BP对独立连续有限LFM自相关PSF检查通过；0/8/70deg三种距离共9项距离加密与几何平移验证通过。
- 70deg最远距WK的Stolt抽头16→32、波数网格密度加倍通过；宽度变化小于0.004%，旁瓣变化小于0.011dB。
- 首次边界9deg、25km处Fr从120→240MHz，RD/CS分类不变；最大旁瓣恶化量变化约0.0315/0.0043dB。
- 独立x=500m回波的四法处理平移验证全部通过，最终源文件对0deg中心点和8deg近距点的6项复现全部通过。
- 导出22张PNG及选定工况的129×129复数地面ROI；人工检查0/8/9/70deg代表图及通过状态图，中文、负号、标注和配色正常。
- 本机实际MATLAB R2022b；源码采用R2021b兼容语法，尚未在实际R2021b安装上执行。

## 实测结论与范围

按两向IRW差异≤15%、PSLR/ISLR相对同角同位置参照恶化≤2dB、定位误差≤0.5个分辨率单元的联合判据：
RD和CS的最大连续已测合格角为8deg，9deg近距边缘点首次不合格；WK、BP在所测网格均通过，最高验证至70deg，未测出其上限。
首次不合格由距离旁瓣触发，不能解释为9deg以上完全无法成像。仅按宽度或定位，粗网格首次失败在20deg，前一已测角为15deg，未对该单项区间继续细化。

以上是固定地面场景、10km最近斜距范围、1m有效天线矩形角域照射、已知真实多普勒中心、无噪声、平地匀速stop-go模型下的具体实现边界。
三距离点分别激励，方位位置用条带平移协变并经独立数据检查；未证明连续全幅或分布式强弱目标场景的聚焦能力。
完整定义、逐点值、阈值敏感性、残余相位和数值风险诊断见notes.md及本目录各表。

## 本地文件

- 原始回波：data/simulated/echo_002_*_run_20261015_squint_boundary/echo.mat，逐份编号见docs/datasets/echo_002_airborne_stripmap_run_20261015_squint_boundary.md。
- 处理结果：results/exp_002_airborne_squint_boundary/run_20261015_squint_boundary/rd、cs、omega_k、bp。
- 方法图片：各方法的figures；跨方法汇总：运行目录figures。
- GitHub保存代码、配置、说明、推导和小型CSV/JSON；data/results/scratch与MAT/PNG未提交。
