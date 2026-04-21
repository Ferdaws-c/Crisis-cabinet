from pypdf import PdfReader

reader = PdfReader("Readme/Chapter08_RiskManagement.pdf")
text = ""
for page in reader.pages:
    text += page.extract_text() + "\n"

print("--- EXCERPT START ---")
print(text[:2000]) # First 2000 chars for layout
print("...")

# Try to find common PMBOK Risk keywords to understand the focus
keywords = ["Identify", "Qualitative", "Quantitative", "Plan Risk Responses", "Avoid", "Mitigate", "Accept", "Transfer"]
for kw in keywords:
    pos = text.find(kw)
    if pos != -1:
        print(f"\n--- Snippet containing '{kw}' ---")
        print(text[max(0, pos-200):min(len(text), pos+400)])
