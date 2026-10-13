# 星载大斜视SAR论文项目

回波生成、信号处理、实验组织和运行数据分别存放。目录规则见 AGENTS.md。

## 新目录
- echo_generation：回波生成的代码、目标、几何和参数。
- signal_processing：rd/cs/omega_k/bp/ffbp各自独立的方法。
- common：统一读写、指标及绘图。
- experiments：实验入口、配置、记录和小型文本指标。
- data：仅本地保存的回波；results：仅本地保存的运行结果。
- docs/datasets：可提交的仿真回波说明。
- scratch：临时尝试；tools：管理脚本。

旧代码与文件已备份到项目外。当前已实现典型机载参数的点目标回波生成与正侧视RD成像。

## 运行第一个实验（MATLAB R2021b）

```matlab
addpath('D:/sar_project/experiments/exp_001_airborne_rd');
summary = run_experiment();
```

每次运行使用新的回波编号和运行编号，不覆盖旧数据。完整回波覆盖10km斜距带，RD处理完整距离带，保存中心复数图像及全场景幅度缩略图。
本地data目录保存回波；results保存图像和MAT结果；experiments保存可上传的参数、指标和研究记录。
RD独立读取已有回波的方法见signal_processing/rd/README.md。

## 绘图规范
成像配色以用户提供的五算法统一参数仿真图片为参考：parula色图、[-40,0]dB成像色标、蓝色剖面曲线。
完整规范见docs/plotting_conventions.md，公共样式入口为common/plotting/sar_plot_style.m。

## 数据编号与实验编号
例如 echo_001_spaceborne_single_45deg、exp_001_bp_baseline。
参数详情写入配置和记录，名称只用于辨认。新参数重新生成时建立新编号，不覆盖旧数据。

## GitHub一次性连接
GitHub上建立私有空仓库，不勾选初始化README、许可证或.gitignore。
在项目根目录PowerShell中执行：

```powershell
git config user.name "你的Git提交署名"
git config user.email "你的Git提交邮箱"
git remote -v
# 仅在尚无origin时添加；替换为自己的真实仓库地址。
git remote add origin https://github.com/你的用户名/sar_project.git
```

如果已经存在origin，检查其地址，不重复添加或盲目修改。
Git首次推送可能要求浏览器认证；不要在代码或聊天里填访问令牌。

## 首次提交框架
先阅读文件，再运行下面命令。此命令提交新框架：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\sync_github.ps1 -Message "chore: 建立SAR论文项目框架" -Paths "AGENTS.md,README.md,.gitignore,echo_generation,signal_processing,common,experiments,docs,tools"
```

## 每次任务完成
Codex按照AGENTS.md检查结果、写记录，然后提交并推送本任务文件。
手动运行MATLAB不会触发同步。自行完成后可调用相同脚本，例如：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\sync_github.ps1 -Message "echo: 完成单点45度回波" -Paths "echo_generation/configs/case_001.m,docs/datasets/echo_001.md"
```

路径示例需替换为真实修改的文件。脚本不上传data/results，不强制覆盖远程。
GitHub只备份代码和研究记录；回波和成像数据需另行本地备份。
旧仓库已跟踪的数据不会因.gitignore自动退出版本管理，首次同步前脚本会检查这一点。
