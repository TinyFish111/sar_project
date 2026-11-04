# CS教材生成与核验

正式成像由MATLAB执行，Python不替代MATLAB回波或CS成像。

- `verify_filters.py`：SymPy核对配方/平移/导数及速度失配残差，NumPy计算指定网格的参考误差；核对正式MATLAB检查通过，检查所有新增MATLAB可执行行均有注释。
- `make_figures.py`：用Matplotlib生成10张中文教学示意图，复制4张正式MATLAB结果图；两类图在文档中明确区分。
- `build_pdf.cjs`：以Markdown为唯一正文，经Pandoc、KaTeX、无头Edge生成PDF。
- `check_pdf.py`：核对正文、章节、公式编号、图片、页面边界并写入Markdown SHA256元数据。

本机示例：

```powershell
D:/anaconda/python.exe tools/spaceborne_cs_teaching/verify_filters.py
D:/anaconda/python.exe tools/spaceborne_cs_teaching/make_figures.py
$env:SAR_PDF_PYTHON = '具有pdfplumber和pypdf的Python绝对路径'
node tools/spaceborne_cs_teaching/build_pdf.cjs
```

Python核验需要NumPy、SymPy，作图需要Matplotlib；PDF检查需要pdfplumber/pypdf。PDF构建需要Pandoc，以及`katex`、`playwright-core`。默认复用项目`scratch/spaceborne_squint_spectrum/runtime/node_modules`，也可用`SAR_PDF_MODULE_ROOT`指定自行安装的依赖目录；它们不提交到Git。Edge路径在构建脚本明确给出。

默认检查/复制的是已核对的正式运行编号，不会因其他运行完成就悄悄切换来源。更换教材案例时，需要显式更改脚本中的运行路径、文档参数和结果，重新检查全部页面；旧教材不覆盖实验原始数据。
