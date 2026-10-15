# 九点成像图集完成与版本绑定

完成日期：2026-10-15，Asia/Shanghai。

## 最终实现版本

图集入口、配置、公共绘图函数及检查记录的本地提交：

`74541c0aab8abdc09c5d87ceb04e7c98d7e36f24`

本文件为该实现提交之后追加的完成说明，不改变取图或绘图代码。
生成阶段HEAD为`a66fe5a8a80061e1f290e1fcd50dc960d3142b83`、dirty=true；
它不包含当时尚未提交的图集代码，不能作为最终实现版本。
gallery_source_manifest.json的6个源文件SHA-256在收尾时复核，差异为0。
原实验52个源文件与原清单一致，算法和回波生成代码没有变化。

## 完成情况

- 从原实验回波重新计算0/8/9/70deg、三个距离、四算法共48份257×257复数ROI。
- 导出40张PNG：16张九格详图、16张单坐标九点幅度拼图、4张四算法对照、4张角度演化。
- 48份复图尺寸、有限值、非零幅度、峰值在窗内检查通过；最窄主瓣至少7.855个采样间隔。
- 新旧复图20个公共真值复数像素的最大相对差异为3.6774591108295355e-8，低于1e-5门限。
- 40张PNG读取检查通过；人工查看0deg九格、8deg/70deg四算法、70deg RD/BP单坐标拼图，中文和布局正常。
- 两次MATLAB运行均以退出码0结束，无剩余计算任务。

本地结果及图片索引：
`results/exp_002_airborne_squint_boundary/run_20261015_nine_probe_gallery/图集索引.md`。
复图分别在该目录rd/cs/omega_k/bp下，PNG在各方法figures及运行级figures下。
原始回波沿用原实验数据集合，原结果只读，本次未新增回波。

九点采用三距离独立回波和已验证的方位平移关系；单坐标拼图压缩块间距，
保持块内真实米制尺度。它不表示同时九目标的相干整幅成像。
各图独立峰值归一化，只用于形状比较；70deg部分RD/CS散焦延伸出16m显示窗，
完整散焦范围不能从此裁剪图读取。原边界判据及结论保持原实验记录中的口径。

## GitHub实际状态

截至本次收尾，**未推送成功**。
两次调用tools/sync_github.ps1均在push阶段返回`Recv failure: Connection was reset`；
第三次仅对该命令临时使用HTTP/1.1重试，返回`Failed to connect to github.com:443`。
本地代码、参数、检查及本完成说明均保留。未更改origin或持久Git网络配置。
本文件追加为独立本地文档提交，提交号由Git历史及任务结束汇报确定。

网络恢复后可以用现有脚本推送当前分支（无选定修改时会直接重试push）：

```powershell
.\tools\sync_github.ps1 -Message 'docs: 绑定九点图集完成记录' -Paths 'experiments/exp_002_airborne_squint_boundary/records/run_20261015_nine_probe_gallery/completion.md'
```

data/results/scratch、MAT和PNG均未加入Git；GitHub只同步代码、配置和小型文本记录。
