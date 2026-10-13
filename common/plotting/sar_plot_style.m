function style = sar_plot_style()
% 全项目默认配色，来源与适用范围见 docs/plotting_conventions.md。
style.colormap_name = 'parula';
style.colormap_size = 256;
style.image_db_limits = [-40,0];
style.profile_db_limits = [-45,2];
style.profile_color = [0,0.4470,0.7410];
style.profile_line_width = 1.2;
style.figure_color = 'white';
end
