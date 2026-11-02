# 变等效速度频谱推导的核验与导出

这些是研究文档的配套工具，不是新的 MATLAB 回波生成或成像处理模块。输入和输出路径均相对脚本所在的项目根目录计算。

## 依赖

- 核验：Python 3、NumPy、SciPy、SymPy、Matplotlib，中文字体 Microsoft YaHei。
- 导出：Node.js、Pandoc 3、Microsoft Edge；Node 包为 `katex` 和 `playwright-core`。
- PDF 检查：Python 的 `pypdf`、`pdfplumber`；视觉检查另需 Poppler 的 `pdftoppm`。

本机科学计算使用 `D:/anaconda/python.exe`。PDF 检查默认使用 Codex 自带 Python；可用环境变量 `SAR_PDF_PYTHON` 指定包含上述 PDF 包的其他解释器。

## 从项目根目录运行

```powershell
# 所有本地安装内容留在忽略的 scratch 目录中。
npm install --prefix scratch/spaceborne_squint_spectrum/runtime --no-audit --no-fund playwright-core katex

# 核验代数和理想圆轨道示例；结果在 scratch 中，不覆盖正式数据。
& D:/anaconda/python.exe tools/spaceborne_squint_spectrum/verify_derivation.py

# 正文或参数改变后，审核并更新正文中的结果与配套小型文本指标。
# 以下复制会更新本推导专用插图和指标，不涉及 data/results。
Copy-Item scratch/spaceborne_squint_spectrum/verification/变等效速度几何与误差.png docs/derivations/spaceborne_squint_variable_vr/变等效速度几何与误差.png
Copy-Item scratch/spaceborne_squint_spectrum/verification/metrics.json docs/derivations/spaceborne_squint_variable_vr/verification_metrics.json

# 从唯一 Markdown 源生成同目录 PDF，并自动检查正文覆盖和元数据摘要。
node tools/spaceborne_squint_spectrum/build_pdf.cjs

# 视觉检查时导出所有页面。
pdftoppm -scale-to 1400 -png docs/derivations/spaceborne_squint_variable_vr/星载斜视SAR变等效速度精确频谱推导.pdf scratch/spaceborne_squint_spectrum/review
```

若 Node 包安装在其他目录，设置 `SAR_PDF_MODULE_ROOT` 为对应 `node_modules` 绝对路径。构建脚本按本机默认 Edge 路径启动无界面排版，不打开可见窗口。

每次改动正文后应重新导出并逐页检查。不要手工修改 PDF 正文，也不要将网格加密结果的一致性表述为未经证明的全频带严格误差界。该工具仅维护本推导专用产物；如需保留新的参数算例版本，应另建有明确编号的研究记录。
