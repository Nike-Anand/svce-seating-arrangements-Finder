import pdfplumber

with pdfplumber.open(r'C:\Users\nikea\AndroidStudioProjects\seating_arrangement\FN-THEORY_1767841202.pdf') as pdf:
    page = pdf.pages[0]  # First page
    text = page.extract_text()
    
    print("First 2000 characters:")
    print(text[:2000])
    
    print("\n" + "="*50)
    
    # Find register number patterns
    import re
    reg_numbers = re.findall(r'\b\d{10,15}\b', text)
    print(f"Found {len(reg_numbers)} register numbers")
    
    # Show context for first 5 register numbers
    for i, reg in enumerate(reg_numbers[:5]):
        start = text.find(reg)
        context = text[max(0, start-30):start+100]
        print(f"\nRegister {reg}:")
        print(f"Context: '{context}'")