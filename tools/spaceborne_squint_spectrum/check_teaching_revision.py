"""检查教材重排后的引用、原公式等价保留及时间原点代数。

输入是上一版 Git 文档与本次可审阅的公式编号映射，避免用旧暂存文件代替版本证据。
"""

from pathlib import Path
import json
import re
import subprocess
import sympy as sp

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / "docs/derivations/spaceborne_squint_variable_vr"
FILE = "docs/derivations/spaceborne_squint_variable_vr/星载斜视SAR变等效速度精确频谱推导.md"
old = subprocess.run(
    ["git", "show", f"c1dd818:{FILE}"], cwd=ROOT, capture_output=True, check=True
).stdout.decode("utf-8")
new = (ROOT / FILE).read_text(encoding="utf-8")
mapping = json.loads((DOC / "formula_migration.json").read_text(encoding="utf-8"))


def formulas(text):
    result = {}
    for block in re.findall(r"\$\$([\s\S]*?)\$\$", text):
        tag = re.search(r"\\tag\{([^}]+)\}", block)
        if tag:
            assert tag.group(1) not in result
            result[tag.group(1)] = block[: tag.start()]
    return result


def remove_boxes(text):
    while r"\boxed{" in text:
        start = text.index(r"\boxed{")
        opening = start + len(r"\boxed")
        depth = 1
        end = opening + 1
        while depth:
            depth += (text[end] == "{") - (text[end] == "}")
            end += 1
        text = text[:start] + text[opening + 1 : end - 1] + text[end:]
    return re.sub(r"\s+", "", text)


old_equations, new_equations = formulas(old), formulas(new)
for old_tag, old_formula in old_equations.items():
    migrated = old_formula.replace(r"\eta_c", r"\eta_{\min}").replace("R_0", "R_b")
    assert remove_boxes(migrated) == remove_boxes(
        new_equations[mapping[old_tag]]
    ), old_tag
references = re.findall(r"(?:式)?（([A-G]|\d+)\.(\d+)）", new)
assert not {f"{a}.{b}" for a, b in references} - new_equations.keys()
assert (
    all(r"\eta_c" not in block for block in new_equations.values()) and "tao" not in new
)
images = re.findall(r"!\[[^\]]*\]\(([^)]+)\)", new)
assert len(images) == 13
assert all((DOC / image).exists() for image in images)
eta, beam, r_b, v, theta = sp.symbols("eta eta_b R_b V theta", real=True)
original = (
    r_b**2 - 2 * r_b * v * sp.sin(theta) * (eta - beam) + v**2 * (eta - beam) ** 2
)
closest_time = beam + r_b * sp.sin(theta) / v
completed = (r_b * sp.cos(theta)) ** 2 + v**2 * (eta - closest_time) ** 2
assert sp.simplify(original - completed) == 0
summary = {
    "previous_git_commit": "c1dd818",
    "original_numbered_equations_preserved": len(old_equations),
    "current_numbered_equations": len(new_equations),
    "numbered_equations_with_boxes": sum(
        r"\boxed" in block for block in new_equations.values()
    ),
    "illustrations": len(images),
    "all_formula_references_resolve": True,
    "beam_center_algebra_passed": True,
}
(DOC / "teaching_revision_checks.json").write_text(
    json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
    newline="\n",
)
print(json.dumps(summary, ensure_ascii=False, indent=2))
