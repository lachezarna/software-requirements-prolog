import docx
from docx.shared import Pt, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml.ns import qn

path = "docs/reference_base.docx"
out = "docs/reference.docx"

d = docx.Document(path)


def set_font(style, name="Times New Roman", size=12, bold=False, italic=False):
    style.font.name = name
    style.font.size = Pt(size)
    style.font.bold = bold
    style.font.italic = italic
    rpr = style.element.get_or_add_rPr()
    rFonts = rpr.find(qn('w:rFonts'))
    if rFonts is None:
        rFonts = rpr.makeelement(qn('w:rFonts'), {})
        rpr.append(rFonts)
    rFonts.set(qn('w:eastAsia'), name)
    rFonts.set(qn('w:cs'), name)


normal = d.styles['Normal']
set_font(normal, size=12)
pf = normal.paragraph_format
pf.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
pf.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
pf.first_line_indent = Cm(1.25)
pf.space_after = Pt(6)

for name, size, bold, italic, align, before, after in [
    ("Title", 20, True, False, WD_ALIGN_PARAGRAPH.CENTER, 0, 24),
    ("Heading 1", 16, True, False, WD_ALIGN_PARAGRAPH.LEFT, 24, 12),
    ("Heading 2", 14, True, False, WD_ALIGN_PARAGRAPH.LEFT, 18, 8),
    ("Heading 3", 13, True, True, WD_ALIGN_PARAGRAPH.LEFT, 12, 6),
]:
    try:
        st = d.styles[name]
    except KeyError:
        continue
    set_font(st, size=size, bold=bold, italic=italic)
    st.paragraph_format.alignment = align
    st.paragraph_format.space_before = Pt(before)
    st.paragraph_format.space_after = Pt(after)
    st.paragraph_format.first_line_indent = Cm(0)
    st.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
    st.paragraph_format.keep_with_next = True

# Compact/code styles used for the Prolog source listings
for name in ["Source Code", "Compact"]:
    try:
        st = d.styles[name]
        set_font(st, name="Consolas", size=10)
        st.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
        st.paragraph_format.first_line_indent = Cm(0)
        st.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT
        st.paragraph_format.space_after = Pt(2)
    except KeyError:
        pass

# Page margins: standard binding-friendly margins for a thesis
for section in d.sections:
    section.left_margin = Cm(3.0)
    section.right_margin = Cm(2.0)
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)

d.save(out)
print("Saved", out)
