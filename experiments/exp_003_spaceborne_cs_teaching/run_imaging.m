function summary = run_imaging(dataset_paths) % 独立入口：只读取已有原始回波并运行CS，不生成或覆盖回波。
project_root = fileparts(fileparts(fileparts(mfilename('fullpath')))); % 根据入口自身位置定位项目。
addpath(fullfile(project_root,'signal_processing','cs'),fullfile(project_root,'common','metrics'),fullfile(project_root,'common','plotting'),fullfile(project_root,'common','io')); % 添加CS和公共模块，不添加任何生成模块。
if ischar(dataset_paths) || isstring(dataset_paths), dataset_paths = cellstr(dataset_paths); end % 独立使用时也支持一个数据路径。
options = spaceborne_cs_options(); % 读取独立处理参数，未借用目标真值。
run_id = ['run_',char(datetime('now','Format','yyyyMMdd_HHmmss_SSS'))]; % 新结果使用唯一运行编号。
result_folder = fullfile(project_root,'results','exp_003_spaceborne_cs_teaching',run_id,'cs'); % 正式图像和MAT结果存放位置。
record_folder = fullfile(project_root,'experiments','exp_003_spaceborne_cs_teaching','records',run_id); % 小型文本指标与运行记录位置。
assert(~exist(result_folder,'dir') && ~exist(record_folder,'dir'),'结果编号已存在，禁止覆盖。'); % 禁止改写既有正式结果。
mkdir(result_folder); mkdir(record_folder); % 建立本次结果及记录目录。
summary.run_id = run_id; % 保存运行编号。
summary.result_folder = result_folder; % 保存正式结果位置。
summary.record_folder = record_folder; % 保存可提交文本指标位置。
summary.processing_provenance = get_project_provenance(project_root,'signal_processing/cs/spaceborne_cs_options.m',0); % 记录处理时实际代码和MATLAB版本。
for index = 1:numel(dataset_paths) % 逐份读取已有回波，生成和处理始终可独立运行。
    loaded = load(dataset_paths{index},'dataset'); % 只读加载原始数据，不保存回原路径。
    dataset = loaded.dataset; clear loaded % 提取结构体并释放多余引用。
    result = run_spaceborne_cs(dataset,options); % 正式执行三相位、分距离段CS处理。
    checks = evaluate_cs_teaching(dataset,result); % 使用公共剖面指标和真值进行独立评价；真值仅在本步骤使用。
    kind = sprintf('scene_%d',numel(dataset.targets.reflectivity)); % 用目标数量区分单点和九点结果。
    if numel(dataset.targets.reflectivity)==1 % 单点额外运行关闭RCMC的对照以验证校正作用。
        control_options = options; control_options.disable_rcmc = true; control_options.range_tile_centers_offset_m = 0; % 只关闭RCMC，保持输入和采样一致。
        control_options.range_output_half_width_m = 5500; % 允许未校正目标仍出现在输出距离窗内。
        control = run_spaceborne_cs(dataset,control_options); % 生成未校正对照图，避免把运行结束当成校正证据。
        result.diagnostics.no_rcmc_image = control.image; % 保存消融图的复数值供绘图与复查。
        result.diagnostics.no_rcmc_range_m = control.slant_range_m; % 保存消融图对应的距离坐标。
        result.diagnostics.no_rcmc_azimuth_m = control.along_track_m; % 保存消融图对应的方位坐标。
        checks.no_rcmc_peak_amplitude = double(max(abs(control.image(:)))); % 保存对照的绝对峰值，避免分别归一化的图隐藏聚焦增益差异。
        checks.cs_vs_no_rcmc_peak_gain_db = 20*log10(double(max(abs(result.image(:))))/checks.no_rcmc_peak_amplitude); % 相同输入与FFT归一化下，记录CS相对对照的峰值幅度增益，单位dB。
        clear control % 对照数据已裁取到结果诊断字段，释放额外结构体。
    end % 单点消融结束。
    save(fullfile(result_folder,[kind,'_image.mat']),'result','checks','-v7.3'); % 保存复数图像、坐标、参数、耗时和评价。
    render_cs_teaching(dataset,result,checks,result_folder,kind); % 用项目统一中文样式绘制过程图、成像图和剖面。
    fid = fopen(fullfile(record_folder,[kind,'_checks.json']),'w','n','UTF-8'); % 打开小型JSON核验记录。
    assert(fid>=0,'无法创建核验记录。'); % 防止路径错误使记录静默丢失。
    fprintf(fid,'%s',jsonencode(checks,'PrettyPrint',true)); fclose(fid); % 保存完整数值指标与判据。
    reproduction.input_path = dataset_paths{index}; reproduction.input_id = dataset.id; % 记录只读输入的路径及编号。
    reproduction.generation_configuration = dataset.configuration; % 保存原始回波中的完整生成参数，便于离线复现。
    reproduction.generation_provenance = dataset.provenance; % 区分生成前版本与本次处理版本。
    reproduction.sampling_checks = dataset.checks; % 保存尺寸、有限值与名义方位频带余量检查。
    reproduction.processing_parameters = result.parameters; % 保存实际使用的处理段、输出窗和相位约定。
    reproduction.processing_provenance = summary.processing_provenance; % 保存成像处理时的实际Git和MATLAB版本。
    fid = fopen(fullfile(record_folder,[kind,'_reproduction.json']),'w','n','UTF-8'); % 建立每份输入独立的可提交复现配置。
    assert(fid>=0,'无法创建复现配置。'); % 确保配置记录失败时明确停止。
    fprintf(fid,'%s',jsonencode(reproduction,'PrettyPrint',true)); fclose(fid); % 写入完整生成、采样和处理配置，不写入回波矩阵。
    summary.datasets(index).path = dataset_paths{index}; % 记录输入的原始回波位置。
    summary.datasets(index).id = dataset.id; % 记录输入回波编号。
    summary.datasets(index).checks = checks; % 将两组检查汇总到独立返回值。
    fprintf('%s：CS耗时%.2fs；检查通过=%d。\n',kind,result.processing_elapsed_s,checks.passed); % 报告实际处理耗时和检查结论。
    clear dataset result % 每组处理完成后释放内存。
end % 所有已有回波处理结束。
fid = fopen(fullfile(record_folder,'summary.json'),'w','n','UTF-8'); % 创建本次处理的总体文本记录。
assert(fid>=0,'无法创建总体记录。'); % 检查总体记录可以写入。
fprintf(fid,'%s',jsonencode(summary,'PrettyPrint',true)); fclose(fid); % 写入路径、版本和逐数据集检查结果。
assert(all(arrayfun(@(item)item.checks.passed,summary.datasets)),'至少一项科学核验未通过，请检查JSON和图像。'); % 判据失败时保留结果并明确报错。
end % 独立成像入口结束。
