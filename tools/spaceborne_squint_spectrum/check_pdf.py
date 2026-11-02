"""检查单源导出的正文覆盖、公式编号、页面边界，并记录源文件摘要。"""
import hashlib
import json
from pathlib import Path
import re
import unicodedata

import pdfplumber
from pypdf import PdfReader, PdfWriter

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = ROOT / "scratch" / "spaceborne_squint_spectrum"
manifest = json.loads((SCRATCH / "render_manifest.json").read_text(encoding="utf-8"))
source = Path(manifest["source"])
pdf_path = Path(manifest["output"])
markdown = source.read_text(encoding="utf-8")
source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
assert source_hash == manifest["sha256"]


def normalize(text):
    return re.sub(r"\s+", "", unicodedata.normalize("NFKC", text))


reader = PdfReader(pdf_path)
pdf_text = "\n".join(page.extract_text() for page in reader.pages)
flat_text = normalize(pdf_text)
missing_prose = [text for text in manifest["prose"] if normalize(text) not in flat_text]
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
    "/Title": "星载斜视 SAR：变等效速度条件下的回波频谱推导",
    "/Subject": "与 Markdown 正文同源的数学推导、误差边界和理想几何核验",
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
    "prose_segments_checked": len(manifest["prose"]),
    "missing_prose_segments": missing_prose,
    "missing_equation_numbers": missing_tags,
    "outside_page": outside_page,
    "outside_body": outside_body,
    "replacement_characters": pdf_text.count("\ufffd"),
    "pdf_bytes": pdf_path.stat().st_size,
}
(SCRATCH / "pdf_checks.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(summary, ensure_ascii=False, indent=2))
