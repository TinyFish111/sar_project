# 条带斜视CS入口

run_cs_squint(cache)只处理已有回波的公共方位频谱缓存，不调用其他成像方法。cache由common/io/prepare_squint_spectrum创建；独立调用方式同RD说明，改为本目录和本入口。

保持旧代码H1/H2/H3的经典Chirp Scaling流程，Km以固定30km最近斜距为参考。方位压缩使用中心精确历程的相位部分，再加常规距离相关方位相位。
中心匹配不能替代精确二维匹配；参考调频率和高阶耦合误差仍在。没有加入非线性CS、子孔径重整或近年改进。

输入复基带echo行慢时间、列快时间；缓存读块在方法内部转为快时间×方位频率。tau单位s，fr/fa单位Hz，最近斜距单位m。
输出native_image为最近斜距×剪切方位，物理坐标映射与相位约定见docs/data_contract.md 2.0。
