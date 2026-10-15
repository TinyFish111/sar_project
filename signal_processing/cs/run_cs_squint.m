function result = run_cs_squint(cache)
% 旧CSA三相位+中心精确方位参考。补充标准距离相关方位相位与几何剪切。
timer = tic; p = squint_processing_axes(cache,8); m = cache.meta;
c = m.configuration.c_mps; v = m.configuration.geometry.speed_mps;
f0 = m.radar.carrier_hz; fs = m.radar.range_sample_rate_hz;
nr = numel(m.fast_time_s);
nup = p.nfft_range*8;
tau = 2*p.range_input_m/c;
tauout = 2*p.range_output_m/(c*p.dref);
tauup = 2*p.range_center_m/c+(-nup/2:nup/2-1)'/(fs*8);
image_spectrum = complex(zeros(numel(p.range_output_m),cache.nfft_azimuth,'single'));
for first = 1:32:cache.nfft_azimuth
    idx = first:min(first+31,cache.nfft_azimuth);
    d = p.d(idx); a = p.dref./d-1;
    km = m.radar.chirp_rate_hz_per_s./(1-m.radar.chirp_rate_hz_per_s*c*p.reference_range_m*p.fa_hz(idx).^2./(2*v^2*f0^3*d.^3));
    data = complex(zeros(p.nfft_range,numel(idx),'single'));
    data(p.range_offset+(1:nr),:) = read_squint_spectrum(cache,idx);
    h1 = pi*(km.*a).*(tau-2*p.reference_range_m./(c*d)).^2;
    data = data.*single(exp(1i*h1));
    spectrum = fftshift(fft(ifftshift(data,1),[],1),1);
    h2 = pi*p.fr_hz.^2./(km.*(1+a))+4*pi*p.reference_range_m/c*p.fr_hz.*(1./d-1/p.dref);
    spectrum = spectrum.*single(exp(1i*h2));
    enlarged = complex(zeros(nup,numel(idx),'single'));
    enlarged(nup/2-p.nfft_range/2+(1:p.nfft_range),:) = spectrum;
    compressed = fftshift(ifft(ifftshift(enlarged,1),[],1),1)*8;
    for k = 1:numel(idx)
        line = interp1(tauup,compressed(:,k),tauout,'linear',0);
        h3 = -pi*km(k)*a(k)*(1+a(k))*(tauout-2*p.reference_range_m/(c*p.dref)).^2;
        haz = 4*pi*f0/c*(p.range_output_m-p.reference_range_m)*(d(k)-p.dref) ...
            +2*pi*cache.doppler_baseband_hz(idx(k))/v*(p.range_output_m-p.reference_range_m)*tan(p.theta_rad);
        image_spectrum(:,idx(k)) = single(line.*exp(1i*(h3+haz))*p.reference_azimuth_filter(idx(k)));
    end
end
[image,p] = finish_squint_image(image_spectrum,p);
result = squint_result(cache,p,image,'CS',toc(timer));
result.parameters.reference_range_m = p.reference_range_m;
result.parameters.azimuth = 'phase-only exact center history + conventional differential phase';
end
