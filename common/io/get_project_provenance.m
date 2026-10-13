function provenance = get_project_provenance(project_root, config_path, seed)
% 记录生成时版本，dirty=true表示该提交号尚不能代表新代码。
[s, commit] = system(sprintf('git -C "%s" rev-parse HEAD',project_root));
if s ~= 0, commit = 'unavailable'; end
[s, state] = system(sprintf('git -C "%s" status --porcelain',project_root));
provenance.git_commit_at_generation = strtrim(commit);
provenance.git_dirty_at_generation = s ~= 0 || ~isempty(strtrim(state));
provenance.configuration_path = config_path;
provenance.random_seed = seed;
provenance.generated_at = char(datetime('now','TimeZone','Asia/Shanghai','Format','yyyy-MM-dd HH:mm:ss Z'));
provenance.matlab_version = version;
provenance.matlab_release = version('-release');
end
