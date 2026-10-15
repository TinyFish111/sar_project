function verify_wk_numerics(run_id)
% 在最大角度/最远距工况加倍Stolt抽头和波数网格密度，核查最坏采样规模。
root = boundary_setup();
out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
validation_path = fullfile(records,'wk_numerical_validation.csv');
if exist(validation_path,'file')
    previous = readtable(validation_path);
    if height(previous)==1 && previous.closest_range_m==35000 && all(previous.converged), return; end
end
work = fullfile(root,'scratch','exp_002',run_id); rows = struct([]);
for range = 35000
    key = sprintf('sq70_r%05d',range);
    saved = load(boundary_result_path(out,key,'WK'),'measured','meta');
    path = fullfile(root,'data','simulated',saved.meta.id,'echo.mat');
    cache = prepare_squint_spectrum(path,fullfile(work,[key,'_verify_spectrum.mat']));
    processing = wk_squint_config(); processing.stolt_taps = 32;
    processing.frequency_grid_refinement = 2;
    native = run_wk_squint(cache,processing);
    finer = measure_probe(@(xy) sample_squint_image(native,xy),saved.meta,false,801);
    base = saved.measured;
    row.angle_deg = 70; row.closest_range_m = range;
    row.stolt_taps = processing.stolt_taps; row.frequency_grid_refinement = processing.frequency_grid_refinement;
    row.irw_change_x_fraction = finer.azimuth.irw_m/base.azimuth.irw_m-1;
    row.irw_change_y_fraction = finer.range.irw_m/base.range.irw_m-1;
    row.pslr_change_x_db = finer.azimuth.pslr_db-base.azimuth.pslr_db;
    row.pslr_change_y_db = finer.range.pslr_db-base.range.pslr_db;
    row.islr_change_x_db = finer.azimuth.islr_db-base.azimuth.islr_db;
    row.islr_change_y_db = finer.range.islr_db-base.range.islr_db;
    row.converged = max(abs([row.irw_change_x_fraction,row.irw_change_y_fraction]))<0.01 ...
        && max(abs([row.pslr_change_x_db,row.pslr_change_y_db,row.islr_change_x_db,row.islr_change_y_db]))<0.2;
    if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
    fprintf('WK_VERIFY %s converged=%d\n',key,row.converged);
    clear native; delete(cache.path);
end
writetable(struct2table(rows),validation_path);
assert(all([rows.converged]),'WK插值或波数网格尚未收敛。');
end
