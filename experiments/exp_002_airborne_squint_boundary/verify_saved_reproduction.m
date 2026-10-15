function verify_saved_reproduction(run_id)
% 最终源文件复现低角度基线，排查分块/裁剪I/O优化是否改变数值结论。
root = boundary_setup(); out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
validation_path = fullfile(records,'final_source_reproduction.csv');
if exist(validation_path,'file')
    previous = readtable(validation_path); if height(previous)==6 && all(previous.pass), return; end
end
rows = struct([]);
for test_case = [0,30000;8,25000]'
    key = sprintf('sq%02d_r%05d',test_case(1),test_case(2));
    saved = load(boundary_result_path(out,key,'BP'),'meta'); meta = saved.meta;
    path = fullfile(root,'data','simulated',meta.id,'echo.mat');
    cache = prepare_squint_spectrum(path,fullfile(root,'scratch','exp_002',run_id,[key,'_replay_spectrum.mat']));
    for method = {'RD','CS','WK'}
        base = load(boundary_result_path(out,key,method{1}),'measured');
        switch method{1}
            case 'RD', native = run_rd_squint(cache);
            case 'CS', native = run_cs_squint(cache);
            case 'WK', native = run_wk_squint(cache);
        end
        replay = measure_probe(@(xy) sample_squint_image(native,xy),meta,false,801);
        original = base.measured;
        row.angle_deg = test_case(1); row.closest_range_m = test_case(2); row.method = method{1};
        row.max_irw_fraction_difference = max(abs([replay.azimuth.irw_m/original.azimuth.irw_m,replay.range.irw_m/original.range.irw_m]-1));
        row.max_side_difference_db = max(abs([replay.azimuth.pslr_db-original.azimuth.pslr_db,replay.range.pslr_db-original.range.pslr_db,replay.azimuth.islr_db-original.azimuth.islr_db,replay.range.islr_db-original.range.islr_db]));
        row.pass = row.max_irw_fraction_difference<1e-4 && row.max_side_difference_db<0.01;
        if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
        fprintf('REPRODUCE %s %s pass=%d\n',key,method{1},row.pass); clear native
    end
    delete(cache.path);
end
writetable(struct2table(rows),validation_path);
assert(all([rows.pass]),'最终源文件与所存低角度结果不一致。');
end
