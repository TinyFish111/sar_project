function verify_boundary_sampling(run_id)
% 首次失效工况把Fr从120提高到240MHz，排除低过采样率主导边界的可能。
root = boundary_setup(); out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
validation_path = fullfile(records,'boundary_sampling_validation.csv');
if exist(validation_path,'file')
    old = readtable(validation_path); if height(old)==2 && all(old.pass), return; end
end
s = summarize_boundary(run_id); selected = s(ismember(string(s.method),["RD","CS"]) & ~s.all_probes_pass,:);
if isempty(selected), return; end
angle = min(selected.angle_deg);
t = readtable(fullfile(records,'metrics.csv'),'TextType','string');
failed = t(t.angle_deg==angle & ismember(t.method,["RD","CS"]) & ~t.pass,:);
range = min(failed.closest_range_m); key = sprintf('sq%02d_r%05d',angle,range);
cfg = airborne_squint_boundary(angle,range,0); cfg.radar.range_sample_rate_hz = 240e6;
id = sprintf('echo_002_fr240_sq%02d_r%05d_%s',angle,range,run_id);
path = fullfile(root,'data','simulated',id,'echo.mat');
if ~exist(path,'file'), generate_stripmap_probe(cfg,root,id); end
saved = load(path,'meta'); meta = saved.meta;
reference = measure_probe(@(xy) bp_values(path,xy),meta,true,801);
cache = prepare_squint_spectrum(path,fullfile(root,'scratch','exp_002',run_id,'boundary_fr240_spectrum.mat'));
criteria = boundary_config(); rows = struct([]);
for method = {'RD','CS'}
    base = load(boundary_result_path(out,key,method{1}),'check');
    switch method{1}
        case 'RD', native = run_rd_squint(cache);
        case 'CS', native = run_cs_squint(cache);
    end
    measured = measure_probe(@(xy) sample_squint_image(native,xy),meta,false,801);
    check = compare_probe(measured,reference,criteria.threshold);
    a = check; b = base.check;
    row.angle_deg = angle; row.closest_range_m = range; row.method = method{1};
    row.range_sample_rate_hz = 240e6;
    row.max_irw_ratio_change = max(abs([a.irw_ratio_x-b.irw_ratio_x,a.irw_ratio_y-b.irw_ratio_y]));
    row.max_side_loss_change_db = max(abs([a.pslr_loss_x_db-b.pslr_loss_x_db,a.pslr_loss_y_db-b.pslr_loss_y_db,a.islr_loss_x_db-b.islr_loss_x_db,a.islr_loss_y_db-b.islr_loss_y_db]));
    row.classification_unchanged = a.pass==b.pass;
    row.pass = row.classification_unchanged && row.max_irw_ratio_change<0.01 && row.max_side_loss_change_db<0.2;
    if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
    fprintf('SAMPLING_VERIFY %s %s stable=%d\n',key,method{1},row.pass); clear native
end
writetable(struct2table(rows),validation_path); delete(cache.path);
assert(all([rows.pass]),'首次边界对Fr加倍敏感，尚不能排除采样因素。');
end
function z = bp_values(path,xy)
r = run_bp_squint(path,xy,4); z = r.values;
end
