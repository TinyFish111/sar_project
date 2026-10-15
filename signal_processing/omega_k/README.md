# 条带斜视omega-k入口

run_wk_squint(cache,processing)只处理已有回波，不调用RD、CS或BP。processing可省略，默认由wk_squint_config给出。
cache由common/io/prepare_squint_spectrum创建，保存去多普勒中心后的公共方位FFT；传播项使用真实多普勒。

处理为经典平方根二维匹配、Stolt重采样、逆变换。按每条映射的完整频带设置输出，16点Lanczos sinc作Stolt插值。
局部频域输出原点平移与全幅Stolt后裁剪等价，用于跳过大量空像素；没有给成像加入目标真值历程。
局部输出FFT加密8倍，距离轴过采样8倍。实验另在70deg最远距工况将Stolt抽头与波数网格密度加倍，核查数值收敛。

输出native_image为最近斜距×剪切方位复图；轴、单位、地面坐标映射和已去除的确定性载波见docs/data_contract.md 2.0。
只验证匀速直线、平地、stop-go、固定波束模型。70deg仍通过不证明更高角度或真实运动误差下仍成立。
