function write_phase_diagnostics(run_id)
% 仅用作机制分析，不参与成像/合格判定；真实fa随fr和角域位置取值。
root = boundary_setup(); records = fullfile(root,'experiments','exp_002_airborne_squint_boundary','records',run_id);
rows = struct([]); scaling_rows = struct([]);
for angle = unique([0:1:15,20:5:70])
    cfg = airborne_squint_boundary(angle,30000,0);
    fr = linspace(-cfg.radar.bandwidth_hz/2,cfg.radar.bandwidth_hz/2,257)';
    psi = deg2rad(angle)+linspace(-0.5,0.5,17)*cfg.geometry.beamwidth_rad;
    fa = 2*cfg.geometry.speed_mps/cfg.c_mps*(cfg.radar.carrier_hz+fr).*sin(psi);
    a = cfg.c_mps*fa/(2*cfg.geometry.speed_mps); f0 = cfg.radar.carrier_hz;
    d = sqrt(1-(a/f0).^2); q = sqrt((f0+fr).^2-a.^2);
    for range = [25000,30000,35000]
        quadratic_ref = 2*pi*30000/cfg.c_mps*a.^2.*fr.^2./(f0^3*d.^3);
        exact = -4*pi*range/cfg.c_mps*(q-f0*d-fr./d)-quadratic_ref;
        edge = 2*pi*(range-30000)/cfg.c_mps*a.^2.*fr.^2./(f0^3*d.^3);
        cubic = -2*pi*range/cfg.c_mps*a.^2.*fr.^3./(f0^4*d.^5);
        row.angle_deg = angle; row.closest_range_m = range;
        row.max_exact_residual_rad = max(abs(exact(:)));
        row.max_range_reference_quadratic_rad = max(abs(edge(:)));
        row.max_cubic_rad = max(abs(cubic(:)));
        if isempty(rows), rows = row; else, rows(end+1) = row; end %#ok<AGROW>
        % 二阶模型内的H1频移估计；高阶项明显时不将它当作严格频谱证明。
        km = 1./(1/cfg.radar.chirp_rate_hz_per_s-2*30000/cfg.c_mps*a.^2./(f0^3*d.^3));
        scale = cos(deg2rad(angle))./d-1;
        inverse_km_target = 1/cfg.radar.chirp_rate_hz_per_s-2*range/cfg.c_mps*a.^2./(f0^3*d.^3);
        tau_offset_bound = 2*abs(range-30000)./(cfg.c_mps*d)+cfg.radar.bandwidth_hz/2*abs(inverse_km_target);
        shift = abs(km.*scale).*tau_offset_bound;
        item.angle_deg = angle; item.closest_range_m = range;
        item.conservative_h1_frequency_shift_hz = max(shift(:));
        item.conservative_post_h1_half_band_hz = cfg.radar.bandwidth_hz/2+max(shift(:));
        item.fast_time_nyquist_hz = cfg.radar.range_sample_rate_hz/2;
        item.conservative_bound_within_nyquist = item.conservative_post_h1_half_band_hz<item.fast_time_nyquist_hz;
        if isempty(scaling_rows), scaling_rows = item; else, scaling_rows(end+1) = item; end %#ok<AGROW>
    end
end
writetable(struct2table(rows),fullfile(records,'src_phase_diagnostic.csv'));
writetable(struct2table(scaling_rows),fullfile(records,'cs_scaling_sampling_diagnostic.csv'));
end
