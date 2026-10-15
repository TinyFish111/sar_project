function path = boundary_result_path(output_dir,key,method)
% 新结果按方法分目录；读取本任务早期检查点时兼容尚未整理的文件。
if strcmpi(method,'WK'), folder_name = 'omega_k'; else, folder_name = lower(method); end
folder = fullfile(output_dir,folder_name); if ~exist(folder,'dir'), mkdir(folder); end
path = fullfile(folder,[key,'.mat']);
legacy = fullfile(output_dir,[key,'_',upper(method),'.mat']);
if ~exist(path,'file') && exist(legacy,'file'), path = legacy; end
end
