import docx

doc = docx.Document("Readme/gppt_student_announcement.docx")
text = []
for para in doc.paragraphs:
    text.append(para.text)

with open("Readme/output.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(text))
