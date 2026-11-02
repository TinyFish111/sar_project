/** 从唯一 Markdown 正文生成 PDF；临时 HTML 和排版检查信息保存在 scratch。 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawnSync } = require('child_process');
const { pathToFileURL } = require('url');

const root = path.resolve(__dirname, '../..');
const scratch = path.join(root, 'scratch/spaceborne_squint_spectrum');
const sourceDir = path.join(root, 'docs/derivations/spaceborne_squint_variable_vr');
const stem = '星载斜视SAR变等效速度精确频谱推导';
const source = path.join(sourceDir, `${stem}.md`);
const output = path.join(sourceDir, `${stem}.pdf`);
const moduleRoot = process.env.SAR_PDF_MODULE_ROOT || path.join(scratch, 'runtime/node_modules');
const { chromium } = require(path.join(moduleRoot, 'playwright-core'));
const katexRoot = path.join(moduleRoot, 'katex/dist');

function run(command, args) {
  const result = spawnSync(command, args, { encoding: 'utf8', cwd: root });
  if (result.status !== 0) throw new Error(`${command}: ${result.stderr || result.error}`);
  return result.stdout;
}

async function main() {
  fs.mkdirSync(scratch, { recursive: true });
  const markdown = fs.readFileSync(source, 'utf8');
  const sha256 = crypto.createHash('sha256').update(markdown).digest('hex');
  const fragment = run('pandoc', [source, '--from=markdown+tex_math_dollars', '--to=html5',
    '--katex', '--wrap=none']);
  const css = `
    @page { size: A4; margin: 18mm 16mm 17mm; }
    * { box-sizing: border-box; }
    html { font-size: 14px; color: #172b3d; }
    body { margin: 0; font-family: 'Microsoft YaHei', 'SimSun', sans-serif;
           line-height: 1.78; overflow-wrap: break-word; }
    h1 { font-size: 26px; line-height: 1.45; color: #143a55;
         border-bottom: 3px solid #0072bd; padding-bottom: 14px; margin: 0 0 20px; }
    h2 { font-size: 21px; color: #143a55; line-height: 1.5;
         margin: 24px 0 15px; padding-top: 5px; }
    h2.chapter-start { break-before: page; margin-top: 0; }
    h3 { font-size: 16px; color: #165d8e; line-height: 1.6; margin: 21px 0 9px; }
    h1, h2, h3 { break-after: avoid; }
    p { margin: 9px 0; orphans: 3; widows: 3; text-align: justify; }
    p:has(+ .math.display) { break-after: avoid; }
    strong { color: #153e5b; }
    table { border-collapse: collapse; width: 100%; font-size: 12.5px;
            line-height: 1.65; margin: 14px 0; break-inside: avoid; }
    thead { display: table-header-group; }
    th { background: #eaf2f8; color: #153e5b; font-weight: 600; }
    th, td { border: 1px solid #c7d5e0; padding: 6px 8px; vertical-align: top; }
    tr { break-inside: avoid; }
    a { color: #165d8e; text-decoration: none; }
    img { display: block; max-width: 100%; margin: 12px auto; break-inside: avoid; }
    code { font-family: Consolas, 'Microsoft YaHei', monospace; font-size: .9em; }
    ol, ul { padding-left: 1.6em; }
    li { margin: 9px 0; }
    .math.display { display: block; margin: 15px 0; padding: 5px 0;
                    break-inside: avoid; break-after: avoid; overflow: visible; }
    .katex-display { margin: 0 !important; }
    .katex { font-size: 1.08em; color: #101c29; }
    .math.inline .katex { font-size: 1.05em; }
    .math.display + p { margin-top: 8px; }
    .math-number { white-space: nowrap; }
  `;
  const htmlPath = path.join(scratch, 'document.html');
  const base = pathToFileURL(sourceDir + path.sep).href;
  const katexCss = pathToFileURL(path.join(katexRoot, 'katex.min.css')).href;
  const html = `<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
    <base href="${base}"><title>${stem}</title>
    <link rel="stylesheet" href="${katexCss}"><style>${css}</style></head>
    <body><main>${fragment}</main></body></html>`;
  fs.writeFileSync(htmlPath, html, 'utf8');
  const browser = await chromium.launch({
    executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    headless: true,
    args: ['--allow-file-access-from-files'],
  });
  try {
    const page = await browser.newPage({ viewport: { width: 673, height: 1000 }, deviceScaleFactor: 1 });
    await page.goto(pathToFileURL(htmlPath).href, { waitUntil: 'load' });
    await page.addScriptTag({ path: path.join(katexRoot, 'katex.min.js') });
    const renderInfo = await page.evaluate(() => {
      for (const heading of document.querySelectorAll('h2')) {
        if (/^(2\.|9\.|13\.|17\.)/.test(heading.textContent)) {
          heading.classList.add('chapter-start');
        }
      }
      const mathNodes = [...document.querySelectorAll('.math')];
      const formulaTexts = [];
      for (const node of mathNodes) {
        const tex = node.textContent;
        const displayMode = node.classList.contains('display');
        window.katex.render(tex, node, { displayMode, throwOnError: true, strict: 'ignore',
          output: 'htmlAndMathml' });
        if (displayMode) formulaTexts.push(tex);
      }
      const walker = document.createTreeWalker(document.querySelector('main'), NodeFilter.SHOW_TEXT);
      const prose = [];
      while (walker.nextNode()) {
        const node = walker.currentNode;
        if (!node.parentElement.closest('.math') && node.textContent.trim().length >= 2) {
          prose.push(node.textContent.trim());
        }
      }
      return { mathCount: mathNodes.length, displayCount: formulaTexts.length, formulaTexts, prose };
    });
    await page.evaluate(() => document.fonts.ready);
    await page.emulateMedia({ media: 'print' });
    const scaleInfo = await page.evaluate(() => {
      const records = [];
      for (const node of document.querySelectorAll('.math.display')) {
        const katexHtml = node.querySelector('.katex-html');
        const available = node.clientWidth;
        const bases = [...katexHtml.children].filter(child => !child.classList.contains('tag'));
        const natural = bases.reduce((sum, item) => sum + item.getBoundingClientRect().width, 0);
        const tag = node.querySelector('.tag');
        const tagWidth = tag ? tag.getBoundingClientRect().width : 0;
        const needed = natural + (tagWidth ? 2 * tagWidth + 24 : 0);
        let scale = Math.min(1, available / needed);
        if (scale < 1) node.style.fontSize = `${scale}em`;
        records.push({ number: tag?.textContent || '', scale, natural, available });
      }
      return records;
    });
    await page.evaluate(() => document.fonts.ready);
    const brokenImages = await page.locator('img').evaluateAll(images =>
      images.filter(image => !image.complete || image.naturalWidth === 0).map(image => image.src));
    if (brokenImages.length) throw new Error(`Images failed: ${brokenImages.join(', ')}`);
    await page.pdf({ path: output, format: 'A4', printBackground: true,
      preferCSSPageSize: true, displayHeaderFooter: true,
      headerTemplate: `<div style="font-size:8px;color:#6d7e8b;width:100%;text-align:center;
        font-family:'Microsoft YaHei',sans-serif;">星载斜视 SAR · 距离空变等效速度频谱推导</div>`,
      footerTemplate: `<div style="font-size:8px;color:#6d7e8b;width:100%;text-align:center;
        font-family:'Microsoft YaHei',sans-serif;"><span class="pageNumber"></span> /
        <span class="totalPages"></span></div>` });
    fs.writeFileSync(path.join(scratch, 'render_manifest.json'), JSON.stringify({
      source, output, sha256, ...renderInfo, scaleInfo, brokenImages,
    }, null, 2), 'utf8');
    const python = process.env.SAR_PDF_PYTHON || path.join(process.env.USERPROFILE,
      '.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe');
    console.log(run(python, [path.join(__dirname, 'check_pdf.py')]));
    console.log(JSON.stringify({ output, sourceSha256: sha256, mathCount: renderInfo.mathCount,
      displayCount: renderInfo.displayCount,
      scaledFormulas: scaleInfo.filter(item => item.scale < .99) }, null, 2));
  } finally {
    await browser.close();
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
