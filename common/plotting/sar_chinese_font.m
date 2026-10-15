function font = sar_chinese_font()
% 优先使用本机MATLAB实际识别的中文字体，避免仅Windows安装但名称不匹配。
persistent selected
if isempty(selected)
    available = listfonts();
    candidates = {'Microsoft YaHei UI','Microsoft YaHei','微软雅黑','Noto Sans SC','SimHei','黑体','SimSun','宋体'};
    for k = 1:numel(candidates)
        index = find(strcmpi(available,candidates{k}),1);
        if ~isempty(index), selected = available{index}; break; end
    end
    assert(~isempty(selected),'没有找到支持中文的字体。');
end
font = selected;
end
