function paths = run_generation() % 独立入口：只生成单点、九点原始回波，绝不启动成像。
project_root = fileparts(fileparts(fileparts(mfilename('fullpath')))); % 从入口位置定位项目根目录，不依赖当前工作目录。
addpath(fullfile(project_root,'echo_generation'),fullfile(project_root,'echo_generation','configs'),fullfile(project_root,'echo_generation','geometry'),fullfile(project_root,'echo_generation','targets'),fullfile(project_root,'common','io')); % 只加入生成和公共读写模块。
cfg = spaceborne_cs_teaching(); % 读取集中定义的雷达、几何、采样与目标参数。
stamp = char(datetime('now','Format','yyyyMMdd_HHmmss_SSS')); % 毫秒时间戳为本次运行建立唯一编号。
names = {'single','nine'}; % 单点用于测RCM和点扩散，九点用于展示场景成像。
paths = cell(1,numel(names)); % 保存两个独立原始数据文件的绝对路径。
for index = 1:numel(names) % 分别生成诊断数据和场景数据，均使用同一雷达参数。
    current = cfg; % 复制配置，避免单点修改污染九点配置。
    if index==1, current.targets.range_offset_m = 0; current.targets.beam_center_time_s = 0; end % 单点仅保留中心目标。
    dataset_id = ['echo_003_spaceborne_cs_',names{index},'_',stamp]; % 每份回波使用独立数据编号。
    folder = fullfile(project_root,'data','simulated',dataset_id); % 正式原始数据保存到规定的data目录。
    assert(~exist(folder,'dir'),'回波目录已存在，禁止覆盖。'); % 避免重复编号覆盖已有数据。
    mkdir(folder); % 创建本次回波专属目录。
    dataset = generate_spaceborne_cs_echo(current,project_root,dataset_id); % 仅调用回波生成器。
    paths{index} = fullfile(folder,'echo.mat'); % 原始数据文件路径。
    save(paths{index},'dataset','-v7.3'); % 保存完整回波、坐标、轨道示意、标定、目标真值和生成版本。
    fprintf('原始回波已保存：%s；矩阵%d×%d。\n',paths{index},size(dataset.echo,1),size(dataset.echo,2)); % 向用户报告数据位置和维度。
    clear dataset % 释放当前回波内存后生成下一份。
end % 两份原始数据生成结束。
end % 独立生成入口结束；后续成像需显式调用另一个入口。
