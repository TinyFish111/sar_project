# 正式运行完成记录

最终实现提交：`932e7c4e5d5dd1039145fe6b6aab391dab8220b0`。

该提交包含本实验最终MATLAB生成与处理代码、完整参数、图文教材、数据说明及小型文本指标，已成功推送既有origin的main分支。此后补充本完成记录，不改变MATLAB源文件或正式实验结果。11个实际MATLAB源文件的字节SHA256见source_hashes.json，已核对一致。

生成前及处理前的Git提交均为`b0ab2e68e4f110ef371962c43b6eb83fa60149a2`且dirty=true，保留在原始数据及reproduction.json内；这两个前置版本不代表最终新实现，不能用它们替代上述最终实现提交。

正式原始回波：

- `data/simulated/echo_003_spaceborne_cs_single_20261104_223344_762/echo.mat`
- `data/simulated/echo_003_spaceborne_cs_nine_20261104_223344_762/echo.mat`

正式图像、完整复数结果及过程图：`results/exp_003_spaceborne_cs_teaching/run_20261104_223510_663/cs/`。数据及MAT结果仅保存在本地，未提交GitHub。

单点、九点预设检查均通过；单点RCM跨度295.6801m降至0.0768m，九点全部逐点评价通过。实际MATLAB为R2022b；采用R2021b兼容语法，不宣称已在R2021b安装上实测。教材26页，14图，36个编号公式，15个核心公式框，Markdown与PDF同源并经全文核对及逐页视觉检查。

结果限于5°斜视、短矩形孔径和距离空变等效双曲模型；不外推真实轨道、真实原始数据、大斜视、宽带或连续分布场景的分段接缝。
