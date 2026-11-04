function summary = run_all() % 便捷总入口；生成和成像仍由两个独立函数完成。
folder = fileparts(mfilename('fullpath')); % 定位本实验入口文件夹。
addpath(folder); % 将本实验三个入口与专用评价绘图函数加入路径。
paths = run_generation(); % 第一步只生成原始回波，返回两个保存路径。
summary = run_imaging(paths); % 第二步只读已有回波，独立完成CS处理和检查。
end % 教学实验便捷入口结束。
