function p = squint_processing_axes(cache, range_upsampling)
% 公共数值坐标，不包含RD/CS/WK算法。原始快时间采用中心样本为FFT原点。
m = cache.meta;
c = m.configuration.c_mps;
fs = m.radar.range_sample_rate_hz;
nr = numel(m.fast_time_s);
p.nfft_range = 2^nextpow2(nr+ceil(m.radar.pulse_duration_s*fs)+32);
p.range_offset = p.nfft_range/2-floor(nr/2);
p.range_center_m = c*m.fast_time_s(floor(nr/2)+1)/2;
p.range_input_m = p.range_center_m+(-p.nfft_range/2:p.nfft_range/2-1)'*c/(2*fs);
p.fr_hz = (-p.nfft_range/2:p.nfft_range/2-1)'*fs/p.nfft_range;
p.theta_rad = deg2rad(m.configuration.geometry.squint_deg);
p.dref = cos(p.theta_rad);
p.nominal_azimuth_width_m = m.configuration.geometry.antenna_length_m/(2*p.dref);
p.reference_range_m = m.configuration.scene.reference_closest_range_m;
p.probe_range_m = m.configuration.scene.probe_closest_range_m;
p.output_step_m = c/(2*fs)*p.dref/range_upsampling;
% 公共ROI只指定输出坐标；参考匹配函数始终使用reference_range_m。
halfspan = 32*0.886*c/(2*m.radar.bandwidth_hz)/p.dref;
nside = ceil(halfspan/p.output_step_m);
p.range_output_m = p.probe_range_m+(-nside:nside)'*p.output_step_m;
p.azimuth_sheared_m = cache.azimuth_sheared_m;
p.fa_hz = cache.doppler_true_hz;
p.d = sqrt(1-(m.radar.wavelength_m*p.fa_hz/(2*m.configuration.geometry.speed_mps)).^2);
assert(all(isreal(p.d) & p.d>0));
% 有限参考信号的相位匹配；不把参考频谱幅值再当作方位加窗。
eta = p.azimuth_sheared_m/m.configuration.geometry.speed_mps;
rref = p.reference_range_m;
offset = -rref*tan(p.theta_rad)+m.configuration.geometry.speed_mps*eta;
look = atan2(-offset,rref);
gate = abs(look-p.theta_rad)<=m.configuration.geometry.beamwidth_rad/2;
href = exp(-4i*pi*hypot(offset,rref)/m.radar.wavelength_m).*exp(-2i*pi*m.geometry.center_doppler_hz*eta).*gate;
hf = fftshift(fft(ifftshift(href)));
p.reference_azimuth_filter = exp(-1i*angle(hf));
end
