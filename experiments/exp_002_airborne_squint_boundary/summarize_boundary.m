function summary = summarize_boundary(run_id)
root = boundary_setup();
records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
t = readtable(fullfile(records,'metrics.csv'),'TextType','string');
angles = unique(t.angle_deg); rows = struct([]);
for method = ["RD","CS","WK","BP"]
    for angle = angles'
        s = t(t.angle_deg==angle & t.method==method,:);
        if height(s)~=3, continue; end
        b = t(t.angle_deg==angle & t.method=="BP",:);
        row.method = char(method); row.angle_deg = angle;
        row.all_probes_pass = all(s.pass) && height(b)==3 && all(b.pass);
        row.reference_valid = height(b)==3 && all(b.pass);
        row.worst_width_deviation = max(abs([s.irw_ratio_x;s.irw_ratio_y]-1));
        row.worst_pslr_loss_db = max([s.pslr_loss_x_db;s.pslr_loss_y_db]);
        row.worst_islr_loss_db = max([s.islr_loss_x_db;s.islr_loss_y_db]);
        row.worst_position_cells = max([s.position_error_x_cells;s.position_error_y_cells]);
        if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
    end
end
summary = struct2table(rows); writetable(summary,fullfile(records,'angle_summary.csv'));
% 沿航迹平移协变的九位置表，明确这是三种距离冲激响应的等价平移。
nine = t([],:); nine.along_track_m = zeros(0,1);
for along = [-500,0,500]
    shifted = t; shifted.along_track_m = repmat(along,height(t),1);
    nine = [nine;shifted]; %#ok<AGROW>
end
writetable(nine,fullfile(records,'nine_position_metrics.csv'));
geometry = struct([]);
for angle = angles'
    generation = airborne_squint_boundary(angle,30000,0);
    th = deg2rad(angle); b = generation.geometry.beamwidth_rad/2;
    v = generation.geometry.speed_mps; c = generation.c_mps;
    rlo = 25000/cos(th-b); rhi = 35000/cos(th+b);
    gx.angle_deg = angle; gx.prf_hz = generation.radar.prf_hz;
    gx.center_instantaneous_slant_km = 30/cos(th);
    gx.minimum_received_slant_km = rlo/1000; gx.maximum_received_slant_km = rhi/1000;
    gx.full_scene_fast_window_s = 2*(rhi-rlo)/c+generation.radar.pulse_duration_s+4e-6;
    gx.full_scene_acquisition_s = (1000+35000*tan(th+b)-25000*tan(th-b))/v;
    gx.receive_window_within_pri = gx.full_scene_fast_window_s < 1/gx.prf_hz;
    gx.farthest_echo_within_pri = 2*rhi/c+generation.radar.pulse_duration_s < 1/gx.prf_hz;
    assert(gx.receive_window_within_pri && gx.farthest_echo_within_pri);
    if isempty(geometry), geometry = gx; else, geometry(end+1) = gx; end %#ok<AGROW>
end
writetable(struct2table(geometry),fullfile(records,'sampling_geometry_checks.csv'));
end
