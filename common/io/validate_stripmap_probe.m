function validate_stripmap_probe(path,meta)
% 独立I/O核查，防止中断后将尚未写完的回波当作完整数据继续处理。
% 生成器按时间顺序写入；检查首/中/末照射脉冲的实际复样本及矩阵尺寸。
source = matfile(path);
assert(isequal(size(source,'echo'),meta.checks.size_slow_fast),'回波尺寸与元数据不符。');
active = find(meta.geometry.illuminated);
indices = active(unique(round(linspace(1,numel(active),3))));
for ia = indices(:)'
    delay = 2*meta.geometry.slant_range_m(ia)/meta.configuration.c_mps;
    [~,ir] = min(abs(meta.fast_time_s-delay));
    sample = double(source.echo(ia,ir));
    dt = meta.fast_time_s(ir)-delay;
    expected = exp(1i*pi*meta.radar.chirp_rate_hz_per_s*dt^2-4i*pi*meta.geometry.slant_range_m(ia)/meta.radar.wavelength_m);
    assert(isfinite(sample) && abs(sample-expected)<1e-5,'回波样本不完整或与所记几何不符；保留原文件并使用新的回波编号。');
end
end
