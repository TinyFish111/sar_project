"""检查单源导出的正文覆盖、公式编号、页面边界，并记录源文件摘要。"""
import hashlib
import json
from pathlib import Path
import re
import unicodedata

import pdfplumber
from pypdf import PdfReader, PdfWriter

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = ROOT / "scratch" / "spaceborne_cs_teaching"
manifest = json.loads((SCRATCH / "render_manifest.json").read_text(encoding="utf-8"))
source = Path(manifest["source"])
pdf_path = Path(manifest["output"])
markdown = source.read_text(encoding="utf-8")
assert "tao" not in markdown, "距离向时间必须统一使用 τ"
assert r"\tau" in markdown and "V_r(r)" in markdown, "当前推导缺少约定符号"
table_pipe_count = None
for line in markdown.splitlines():
    if line.startswith("|"):
        count = len(re.findall(r"(?<!\\)\|", line))
        if table_pipe_count is None:
            table_pipe_count = count
        else:
            assert count == table_pipe_count, "表格列数不一致；数学绝对值请用 lvert/rvert"
    else:
        table_pipe_count = None
source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
assert source_hash == manifest["sha256"]


def normalize(text):
    return re.sub(r"\s+", "", unicodedata.normalize("NFKC", text))


reader = PdfReader(pdf_path)
pdf_text = "\n".join(page.extract_text() for page in reader.pages)
flat_text = normalize(pdf_text)
expected_headings = re.findall(r"(?m)^#{1,3}\s+(.+)$", markdown)
rendered_headings = {normalize(text) for text in manifest["headingTexts"]}
assert all(normalize(text) in rendered_headings for text in expected_headings), "部分章节标题未解析为标题"
missing_prose = []
page_split_segments = 0
for text in manifest["prose"]:
    if normalize(text) in flat_text:
        continue
    # 长段落跨页时，PDF 文本流会在中间插入该页的数学字形与页眉页脚。
    # 此时逐短句保留次序内的精确文字匹配，避免把正常分页判成正文缺失。
    clauses = [part for part in re.split(r"(?<=[，。；！？])", text) if normalize(part)]
    if len(clauses) > 1 and all(normalize(part) in flat_text for part in clauses):
        page_split_segments += 1
    else:
        missing_prose.append(text)
tags = re.findall(r"\\tag\{([^}]+)\}", markdown)
assert len(tags) == len(set(tags)), "公式编号重复"
missing_tags = [tag for tag in tags if f"({tag})" not in flat_text]
assert not missing_tags, f"PDF 缺少公式编号：{missing_tags}"
assert not missing_prose, f"PDF 正文未完整覆盖：{missing_prose}"
assert "\ufffd" not in pdf_text, "PDF 存在替代字形"

outside_page = []
outside_body = []
with pdfplumber.open(pdf_path) as pdf:
    for index, page in enumerate(pdf.pages, start=1):
        for char in page.chars:
            # 页眉页脚另行渲染，不计入正文边界检查。
            if char["x0"] < -1 or char["x1"] > page.width+1:
                outside_page.append((index, char["text"], char["x0"], char["x1"]))
            if 48 < char["top"] < page.height-48:
                if char["x0"] < 43 or char["x1"] > page.width-43:
                    outside_body.append((index, char["text"], round(char["x0"], 2), round(char["x1"], 2)))
assert not outside_page, f"字形越出物理页面：{outside_page[:20]}"
assert not outside_body, f"字形越出正文边界：{outside_body[:20]}"

writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.add_metadata({
    "/Title": "星载斜视SAR的CS算法图解与MATLAB实验",
    "/Subject": "三相位CS推导、距离空变速度、独立MATLAB仿真及RCM实测核验",
    "/Author": "SAR 论文项目",
    "/SourceMarkdownSHA256": source_hash,
    "/NumberedEquations": str(len(tags)),
})
temporary = SCRATCH / "with_metadata.pdf"
with temporary.open("wb") as stream:
    writer.write(stream)
temporary.replace(pdf_path)
reopened = PdfReader(pdf_path)
assert reopened.metadata["/SourceMarkdownSHA256"] == source_hash
assert len(reopened.pages) == len(reader.pages)

summary = {
    "source_sha256": source_hash,
    "page_count": len(reopened.pages),
    "numbered_equations": len(tags),
    "math_expressions": manifest["mathCount"],
    "headings_checked": len(expected_headings),
    "images_rendered": manifest["imageCount"],
    "prose_segments_checked": len(manifest["prose"]),
    "page_split_segments_checked_by_clause": page_split_segments,
    "missing_prose_segments": missing_prose,
    "missing_equation_numbers": missing_tags,
    "outside_page": outside_page,
    "outside_body": outside_body,
    "replacement_characters": pdf_text.count("\ufffd"),
    "pdf_bytes": pdf_path.stat().st_size,
}
(SCRATCH / "pdf_checks.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(summary, ensure_ascii=False, indent=2))
