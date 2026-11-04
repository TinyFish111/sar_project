# echo_003_spaceborne_cs_single_20261104_223344_762

## 数据与模型

- 本地文件：`D:/sar_project/data/simulated/echo_003_spaceborne_cs_single_20261104_223344_762/echo.mat`；复数single、慢时间×快时间，2048×4096。
- 模型：时间内恒速、距离空变Vr的完整等效双曲线；5°前向斜视，0.6s矩形有效照射。不是实际轨道欧氏回波。
- 最近斜距中心850km；1个静止点目标。坐标是最近斜距r及波束中心时刻eta_b，非地面XYZ。
- 雷达：5.3GHz载频，15.50829MHz带宽，37.1μs脉宽，18.962468MHz快时间采样率，PRF1700Hz；正距离调频。
- 参数来源：ISCE2固定版本b7702cfbd571681a133ebc5c3b23a10c78d52706的ERS.py用于带宽/采样率，ESA与NASA用于ERS量级载频/高度/脉宽。斜视角、有效孔径和场景为教学设置。

## 保存内容和检查

`dataset`包含echo、fast_time_s、slow_time_s、radar、geometry、targets、truth、processing_state、configuration、provenance、checks。geometry内圆轨道是参数来源的示意轨迹；回波使用等效模型距离，标注trajectory_role。速度标定表供处理器使用，目标真值只供事后评价。

尺寸和有限值检查通过，所有照射和脉冲支持完整位于采样窗内。名义距离频带边缘与有效孔径内最大去中心多普勒为643.534245Hz，相对PRF/2余量206.465755Hz；有限脉冲尾部并不严格限带。

生成前版本`b0ab2e68e4f110ef371962c43b6eb83fa60149a2`，dirty=True；它不代表最终新代码版本。实际MATLAB版本9.13.0.2049777 (R2022b)。完整配置和版本见`experiments/exp_003_spaceborne_cs_teaching/records/run_20261104_223510_663/scene_1_reproduction.json`；最终代码哈希与提交见同目录source_hashes.json及完成记录。

## 成像与限制

已由独立CS处理器只读成像，正式结果`results/exp_003_spaceborne_cs_teaching/run_20261104_223510_663/cs/scene_1_image.mat`，预设位置、主瓣和旁瓣检查通过。单点另验证RCM跨度295.680m降到0.0768m。输出坐标为最近斜距与vref*eta_b，不作地理编码。

无噪声点目标与准确标定，仅验证当前等效模型及5°教学工况；不外推真实轨道、大斜视、宽带和连续场景分段接缝。原始数据只保存在本地，不提交GitHub。
