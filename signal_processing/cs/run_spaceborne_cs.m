function result = run_spaceborne_cs(dataset, options) % 独立读取原始数据并执行三相位CS；不生成回波，不读取目标真值。
timer = tic; % 开始记录纯处理耗时，单位s。
assert(strcmp(dataset.processing_state,'raw_complex_baseband_no_range_compression'),'必须输入原始未压缩回波。'); % 防止重复距离压缩。
c = dataset.radar.propagation_speed_mps; % 传播速度，单位m/s。
fc = dataset.radar.carrier_hz; % 载频，单位Hz。
kr = dataset.radar.chirp_rate_hz_per_s; % 发射脉冲调频率，单位Hz/s。
fs = dataset.radar.range_sample_rate_hz; % 距离采样率，单位Hz。
prf = dataset.radar.prf_hz; % 方位采样率，单位Hz。
rref = dataset.configuration.scene.reference_closest_range_m; % 场景中心最近斜距，单位m；属于雷达标定配置而非目标真值。
vref = dataset.geometry.reference_velocity_mps; % 中心参考等效速度，单位m/s。
fdc = dataset.geometry.center_doppler_hz; % 已知真实多普勒中心，单位Hz；可以超出一个PRF。
theta = deg2rad(dataset.geometry.squint_deg); % 正向斜视角，单位rad。
[na,nr] = size(dataset.echo); % 原始矩阵尺寸Na×Nr，行慢时间、列快时间。
naz = 2^nextpow2(na*options.azimuth_padding_factor); % 方位FFT长度，采用偶数2的幂。
offset = naz/2-na/2; % 双边补零时原始记录中心的整数行偏移。
fb = (-naz/2:naz/2-1)'*prf/naz; % Naz×1去中心方位频率，单位Hz。
fa = fb+fdc; % Naz×1真实方位频率；D和Km必须使用本变量，不能误用fb。
fr = (-nr/2:nr/2-1)*fs/nr; % 1×Nr距离频率，单位Hz；快时间原点位于数组中心。
tau = dataset.fast_time_s; % 1×Nr绝对快时间，单位s；H1/H3不能误用相对时间。
range_axis = c*tau/2; % 1×Nr输出最近斜距轴，单位m；本实现Dref=1，无距离重采样。
eta_out = (-naz/2:naz/2-1)'/prf; % Naz×1输出波束中心时间轴，单位s。
x_axis = vref*eta_out; % Naz×1方位标度轴，单位m；不是经过地理编码的地面距离。
keep_r = find(abs(range_axis-rref)<=options.range_output_half_width_m); % 输出距离列索引。
keep_a = find(abs(x_axis)<=options.azimuth_output_half_width_m); % 输出方位行索引。
padded = complex(zeros(naz,nr,'single')); % Naz×Nr双边补零后的临时回波，复数single。
padded(offset+(1:na),:) = dataset.echo.*single(exp(-2i*pi*fdc*dataset.slow_time_s)); % 去除真实多普勒中心的时间线性相位。
rd = fftshift(fft(ifftshift(padded,1),[],1),1); % 对慢时间做中心化FFT，得到S(tau,fb)。
clear padded % 释放补零数组，后续始终保留原始dataset不变。
native_image = complex(zeros(numel(keep_a),numel(keep_r),'single')); % 输出方位×距离复数图像。
tile_centers = rref+options.range_tile_centers_offset_m; % 预先配置的三个距离参考中心，单位m。
[~,owner] = min(abs(range_axis(keep_r)-tile_centers'),[],1); % 每个输出距离列归属最近参考中心，构成无重叠距离段。
diagnostic_rows = find(abs(fb)<=0.35*prf); % 保存有照射支持的主要方位频带；后续指标进一步使用真实有效带宽。
diagnostic_columns = find(abs(range_axis-rref-2000)<=3500); % 同时覆盖波束中心斜距与最近斜距的RCM诊断窗，单位m。
center_tile = find(abs(tile_centers-rref)==min(abs(tile_centers-rref)),1); % 确定绘制RCM过程的中心距离段。
for tile = 1:numel(tile_centers) % 各距离段独立使用本段Vr，避免全场景固定等效速度。
    r0 = tile_centers(tile); % 本段参考最近斜距，单位m。
    v0 = interp1(dataset.geometry.velocity_range_m,dataset.geometry.equivalent_velocity_mps,r0,'pchip'); % 读取与目标位置无关的Vr标定值，单位m/s。
    d = sqrt(1-(c*fa/(2*v0*fc)).^2); % Naz×1迁移因子D，保留真实方位频率的平方根关系。
    a = 1./d-1; % Naz×1缩放量a；本实现把各频率的距离轴对齐到Dref=1。
    km = kr./(1-kr*c*r0*fa.^2./(2*v0^2*fc^3*d.^3)); % Naz×1混合域距离调频率，包含二次距离耦合补偿。
    assert(isreal(d) && all(d>0) && all(km>0),'频谱超出本CS推导适用域。'); % 排除根号非传播区域和调频率奇点。
    work = rd; % 使用写时复制建立本段数据，不改写公共原始方位频谱。
    for first = 1:options.block_rows:naz % 分块应用H1，避免建立全尺寸double相位矩阵。
        rows = first:min(first+options.block_rows-1,naz); % 本块方位频率行号。
        phase1 = pi*(km(rows).*a(rows)).*(tau-2*r0./(c*d(rows))).^2; % H1相位：围绕参考目标的迁移轨迹添加二次相位，单位rad。
        if options.disable_rcmc, phase1(:) = 0; end % 消融实验关闭CS缩放，相位置零。
        work(rows,:) = work(rows,:).*single(exp(1i*phase1)); % 乘H1，将不同距离目标的差动RCM改成共同偏移。
    end % H1计算结束。
    work = fftshift(fft(ifftshift(work,2),[],2),2); % 距离FFT，得到二维频域数据。
    for first = 1:options.block_rows:naz % 分块应用H2，在二维频域完成距离压缩和共同RCM校正。
        rows = first:min(first+options.block_rows-1,naz); % 当前方位频率块。
        phase2 = pi*fr.^2./(km(rows).*(1+a(rows)))+4*pi*r0/c*(1./d(rows)-1).*fr; % H2：二次频率项压缩，线性频率项平移距离，单位rad。
        if options.disable_rcmc, phase2 = pi*fr.^2/kr+zeros(numel(rows),1); end % 消融仅保留发射脉冲的普通距离匹配相位。
        work(rows,:) = work(rows,:).*single(exp(1i*phase2)); % 相位相乘；有限距离脉冲自身限制带宽，不额外硬截带。
    end % H2计算结束。
    work = fftshift(ifft(ifftshift(work,2),[],2),2); % 距离IFFT，返回已压缩的距离多普勒域。
    if tile==center_tile % 仅保存中心段的诊断图和脊线，不重复存所有完整中间矩阵。
        result.diagnostics.after_rcmc = abs(work(diagnostic_rows,diagnostic_columns)); % H2后幅度，行方位频率、列距离。
        result.diagnostics.doppler_baseband_hz = fb(diagnostic_rows); % 诊断图的去中心方位频率，单位Hz。
        result.diagnostics.range_offset_m = range_axis(diagnostic_columns)-rref; % 诊断图的最近斜距偏移，单位m。
        [~,peak_after] = max(abs(work(diagnostic_rows,diagnostic_columns)),[],2); % H2后每行峰值的局部列索引。
        result.diagnostics.ridge_after_m = range_axis(diagnostic_columns(peak_after))'; % H2后峰值最近斜距，单位m。
        before = rd(diagnostic_rows,:); % 从未经CS的公共方位频谱构建独立的常规距离压缩诊断。
        before = fftshift(fft(ifftshift(before,2),[],2),2).*single(exp(1i*pi*fr.^2/kr)); % 仅对发射波形二次频谱相位取共轭，未校正RCM。
        before = fftshift(ifft(ifftshift(before,2),[],2),2); % 返回未作RCMC的压缩混合域。
        result.diagnostics.before_rcmc = abs(before(:,diagnostic_columns)); % 保存RCMC前幅度。
        [~,peak_before] = max(abs(before(:,diagnostic_columns)),[],2); % 提取校正前距离峰值列。
        result.diagnostics.ridge_before_m = range_axis(diagnostic_columns(peak_before))'; % 校正前峰值斜距，单位m。
        clear before % 及时释放单点诊断临时数组。
    end % 中心段诊断完成。
    tile_columns = find(owner==tile); % 当前段拥有的输出列位置。
    actual_columns = keep_r(tile_columns); % 当前段拥有的完整距离FFT数组列号。
    r = range_axis(actual_columns); % 当前段输出像素最近斜距，1×Ntile，单位m。
    v = interp1(dataset.geometry.velocity_range_m,dataset.geometry.equivalent_velocity_mps,r,'pchip'); % 按输出距离更新方位匹配速度，1×Ntile，单位m/s。
    selected = work(:,actual_columns); % 裁取本段所需复数数据，Naz×Ntile。
    clear work % 完整距离数组此后不再使用，降低峰值内存。
    for first = 1:options.block_rows:naz % 分块应用H3，去剩余距离相位并完成距离相关方位匹配。
        rows = first:min(first+options.block_rows-1,naz); % 当前方位频率块。
        dr = sqrt(1-(c*fa(rows)./(2*fc*v)).^2); % 按每个输出r更新D(fa,r)，Nblock×Ntile。
        residual = -pi*(km(rows).*a(rows).*(1+a(rows))).*(2*(r-r0)/c).^2; % 抵消H1留下的目标距离相关常相位，单位rad。
        dc = sqrt(1-(c*fdc./(2*fc*v)).^2); % 在已去除的真实中心频率处计算参考D，1×Ntile。
        azimuth = 4*pi*fc/c*r.*(dr-dc)+2*pi*fb(rows).*(r*tan(theta)./v); % 仅对消随fb变化的方位相位，并把eta_min平移为eta_b；保留目标常相位以避免人为距离相位调制。
        if options.disable_rcmc, residual(:) = 0; end % 消融未添加H1，因此也不施加对应剩余相位补偿。
        selected(rows,:) = selected(rows,:).*single(exp(1i*(residual+azimuth))); % 乘H3；不对振荡幅度求逆，不冒充精确逆算子。
    end % H3计算结束。
    selected = fftshift(ifft(ifftshift(selected,1),[],1),1); % 方位IFFT，把相干频谱压成点目标。
    native_image(:,tile_columns) = selected(keep_a,:); % 只保留当前段核心输出列；无RCMC插值，无距离拼接重采样。
end % 全部参考距离段处理结束。
result.image = native_image; % 输出方位×最近斜距的复数single图像。
result.slant_range_m = range_axis(keep_r); % 1×Nrange最近斜距坐标，单位m。
result.along_track_m = x_axis(keep_a); % Nazout×1方位标度vref*eta_b，单位m。
result.coordinate_system = 'closest slant range r; azimuth scale vref*eta_b; not geocoded ground coordinates'; % 解释成像轴，防止斜距误标为地距。
result.input_dataset_id = dataset.id; % 保存处理输入的数据编号。
result.method = 'three_phase_range_tiled_chirp_scaling'; % 明确方法采用三相位CS与距离分段参考。
result.parameters = options; % 保存独立处理配置。
result.parameters.reference_velocity_mps = vref; % 记录参考等效速度，单位m/s。
result.parameters.tile_reference_range_m = tile_centers; % 记录实际使用的距离段中心，单位m。
result.parameters.frequency_convention = 'fa=fb+known true fdc; FFT uses exp(-j2*pi*f*t)'; % 保存傅里叶符号与真实频率约定。
result.processing_elapsed_s = toc(timer); % 记录算法本身耗时，不包含绘图、保存或回波生成。
end % CS处理结束；原始dataset未被修改。
