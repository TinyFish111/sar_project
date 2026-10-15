function values = ideal_stripmap_psf(meta, xy_m)
% 独立校验BP：对有限矩形LFM的连续自相关作精确几何相干求和。
% 此函数只作真值验证，成像算法不得调用；不读取/替代正式原始回波。
cfg = meta.configuration; c = cfg.c_mps; lambda = meta.radar.wavelength_m;
tr = meta.radar.pulse_duration_s; kr = meta.radar.chirp_rate_hz_per_s;
rmin = hypot(xy_m(:,2),cfg.geometry.height_m); theta = deg2rad(cfg.geometry.squint_deg);
active = find(meta.geometry.illuminated);
values = complex(zeros(size(xy_m,1),1));
for first = 1:64:numel(active)
    idx = active(first:min(first+63,numel(active)));
    xp = meta.geometry.platform_along_m(idx).';
    range = hypot(xy_m(:,1)-xp,rmin);
    delta = 2*(range-meta.geometry.slant_range_m(idx).')/c;
    overlap = max(0,tr-abs(delta)); argument = kr*delta.*overlap;
    ac = ones(size(argument)); nz = abs(argument)>1e-12;
    ac(nz) = sin(pi*argument(nz))./(pi*argument(nz));
    gate = abs(atan2(xy_m(:,1)-xp,rmin)-theta)<=cfg.geometry.beamwidth_rad/2;
    values = values+sum(overlap/tr.*ac.*exp(4i*pi*(range-meta.geometry.slant_range_m(idx).')/lambda).*gate,2);
end
phase_range = hypot(xy_m(:,1)-meta.geometry.platform_mid_along_m,rmin);
values = values.*exp(-4i*pi*phase_range/lambda);
end
