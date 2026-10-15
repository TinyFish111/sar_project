function write_dataset_description(run_id)
root = boundary_setup();
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
t = readtable(fullfile(records,'metrics.csv'),'TextType','string');
cases = unique([t.angle_deg,t.closest_range_m],'rows');
folders = dir(fullfile(root,'data','simulated',['echo_002_*',run_id])); folders = folders([folders.isdir]);
path = fullfile(root,'docs','datasets',['echo_002_airborne_stripmap_',run_id,'.md']);
f = fopen(path,'w','n','UTF-8'); assert(f>=0); clean = onCleanup(@() fclose(f));
fprintf(f,'# 机载条带大斜视独立点目标回波集合\n\n运行编号：%s。\n\n',run_id);
fprintf(f,'正式扫描含%d种角度、%d种角度/距离工况，每工况四法共用一份实际LFM回波；另有独立x=500m平移检查及首次边界Fr加倍检查。集合共%d份MAT原始数据。\n\n',numel(unique(t.angle_deg)),size(cases,1),numel(folders));
fprintf(f,'固定最近斜距中心30km、最近斜距范围25至35km，固定地面场景y=sqrt(r^2-H^2)。方位测试位置-500/0/500m；主数据分别激励近/中/远点，其他方位位置利用条带平移协变并经数值检查。不是同时九点的完整分布式场景数据。\n\n');
fprintf(f,'H=10km，v=250m/s，f0=9.4GHz，B=100MHz，Tr=10us，Kr=1e13Hz/s，Fr=120MHz，1m有效方位天线。理想固定角宽矩形照射，无噪声、无衰减、平地、匀速、stop-go。PRF按完整二维谱支撑加余量重算；快慢时间窗按逐点几何重算。\n\n');
fprintf(f,'echo矩阵行慢时间、列快时间，复数single；meta保存秒制采样轴、雷达、平台轨迹、目标、配置、照射区间、生成HEAD/dirty状态与检查。格式2.0/2.1的配置别名差异见[数据约定](../data_contract.md)，实际波形模型一致，旧数据不覆盖。\n\n');
fprintf(f,'2.0中的实际照射时间与瞬时斜距应读取geometry.entry_exit_s/slant_range_m与checks，不读取继承的正侧视3.4s/30km别名。统一几何摘要见实验记录sampling_geometry_checks.csv。\n\n');
fprintf(f,'检查：生成块有限、脉冲完整入窗；首/中/末脉冲复样本与所记几何一致；全幅PRI兼容性；独立解析PSF、BP/WK数值加密、平移处理和最终源文件复现。实际通过状态见实验记录各validation.csv。\n\n');
fprintf(f,'指标和结论：[实验记录](../../experiments/exp_002_airborne_squint_boundary/records/%s/conclusions.md)。最终实现提交号见同目录completion.md；生成时的旧HEAD且dirty=true不代表最终代码版本。\n\n',run_id);
fprintf(f,'| 回波编号 | 角度 / deg | 最近斜距 / km | 方位位置 / m | Fr / MHz | 格式 |\n|---|---:|---:|---:|---:|---|\n');
for k = 1:numel(folders)
    saved = load(fullfile(folders(k).folder,folders(k).name,'echo.mat'),'meta'); m = saved.meta;
    fprintf(f,'| %s | %g | %g | %g | %g | %s |\n',folders(k).name,m.configuration.geometry.squint_deg,m.configuration.scene.probe_closest_range_m/1000,m.configuration.targets.along_track_m,m.radar.range_sample_rate_hz/1e6,m.schema_version);
end
fprintf(f,'\n本地数据路径为data/simulated/<回波编号>/echo.mat；GitHub只保存代码、参数说明与小型文本指标，不上传MAT和成像产物。\n');
end
