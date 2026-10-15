function result = run_rd_squint(cache)
% RD+中心参考SRC+逐距离RCMC。参考距离固定30km，不以探测点真值重匹配。
% 读入范围×方位频率的小块；输出最近斜距×剪切方位的复图像。
timer = tic; p = squint_processing_axes(cache,8); m = cache.meta;
c = m.configuration.c_mps; v = m.configuration.geometry.speed_mps;
f0 = m.radar.carrier_hz; fs = m.radar.range_sample_rate_hz;
nr = numel(m.fast_time_s); nup = p.nfft_range*8;
image_spectrum = complex(zeros(numel(p.range_output_m),cache.nfft_azimuth,'single'));
rup = p.range_center_m+(-nup/2:nup/2-1)'*c/(2*fs*8);
for first = 1:32:cache.nfft_azimuth
    idx = first:min(first+31,cache.nfft_azimuth);
    data = complex(zeros(p.nfft_range,numel(idx),'single'));
    data(p.range_offset+(1:nr),:) = read_squint_spectrum(cache,idx);
    spectrum = fftshift(fft(ifftshift(data,1),[],1),1);
    inverse_km = 1/m.radar.chirp_rate_hz_per_s-c*p.reference_range_m*p.fa_hz(idx).^2./(2*v^2*f0^3*p.d(idx).^3);
    spectrum = spectrum.*single(exp(1i*pi*p.fr_hz.^2.*inverse_km));
    spectrum(abs(p.fr_hz)>m.radar.bandwidth_hz/2,:) = 0;
    enlarged = complex(zeros(nup,numel(idx),'single'));
    enlarged(nup/2-p.nfft_range/2+(1:p.nfft_range),:) = spectrum;
    compressed = fftshift(ifft(ifftshift(enlarged,1),[],1),1)*8;
    for k = 1:numel(idx)
        % 压缩后先8倍带限加密，再按每个输出距离的R/D轨迹重采样。
        line = interp1(rup,compressed(:,k),p.range_output_m/p.d(idx(k)),'linear',0);
        phase = 4*pi*f0/c*(p.range_output_m-p.reference_range_m)*(p.d(idx(k))-p.dref) ...
            +2*pi*cache.doppler_baseband_hz(idx(k))/v*(p.range_output_m-p.reference_range_m)*tan(p.theta_rad);
        image_spectrum(:,idx(k)) = single(line.*exp(1i*phase)*p.reference_azimuth_filter(idx(k)));
    end
end
[image,p] = finish_squint_image(image_spectrum,p);
result = squint_result(cache,p,image,'RD',toc(timer));
result.parameters.src_reference_m = p.reference_range_m;
result.parameters.rcmc = 'range-dependent R/D; 8x range interpolation';
end
