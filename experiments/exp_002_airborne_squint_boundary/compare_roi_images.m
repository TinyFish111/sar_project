function compare_roi_images(run_id)
% 补充二维形态检查：同一地面ROI的归一化幅度RMS差，不替代主判据。
root = boundary_setup(); out = fullfile(root,'results','exp_002_airborne_squint_boundary',run_id);
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
bp_files = dir(fullfile(out,'bp','sq*_roi.mat')); rows = struct([]);
for k = 1:numel(bp_files)
    base = load(fullfile(bp_files(k).folder,bp_files(k).name),'focused');
    ref = abs(base.focused.image); ref = ref/max(ref(:));
    for method = {'RD','CS','WK'}
        if strcmp(method{1},'WK'), folder = 'omega_k'; else, folder = lower(method{1}); end
        path = fullfile(out,folder,bp_files(k).name);
        if ~exist(path,'file'), continue; end
        saved = load(path,'focused'); value = abs(saved.focused.image);
        assert(isequal(saved.focused.along_track_m,base.focused.along_track_m) && isequal(saved.focused.cross_track_m,base.focused.cross_track_m));
        value = value/max(max(value(:)),realmin);
        row.case_key = strrep(bp_files(k).name,'_roi.mat',''); row.method = method{1};
        row.normalized_amplitude_rms_difference = sqrt(mean((value(:)-ref(:)).^2));
        row.normalized_amplitude_max_difference = max(abs(value(:)-ref(:)));
        row.passed_primary_criterion = saved.focused.passed_unified_criterion;
        if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
    end
end
writetable(struct2table(rows),fullfile(records,'local_2d_amplitude_comparison.csv'));
end
