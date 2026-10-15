function organize_boundary_results(run_id)
% 仅移动本运行内早期检查点产生的算法结果，保留原文件内容，禁止覆盖。
root = boundary_setup(); out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
files = dir(fullfile(out,'sq*_*.mat'));
for k = 1:numel(files)
    token = regexp(files(k).name,'^(sq\d+_r\d+)_(RD|CS|WK|BP)\.mat$','tokens','once');
    if isempty(token), continue; end
    key = token{1}; method = token{2};
    if strcmp(method,'WK'), folder = 'omega_k'; else, folder = lower(method); end
    destination = fullfile(out,folder); if ~exist(destination,'dir'), mkdir(destination); end
    source = fullfile(files(k).folder,files(k).name); target = fullfile(destination,[key,'.mat']);
    assert(startsWith(source,[out,filesep]) && startsWith(target,[out,filesep]));
    assert(~exist(target,'file'),'不得覆盖正式结果。');
    [ok,message] = movefile(source,target); assert(ok,message);
end
end
