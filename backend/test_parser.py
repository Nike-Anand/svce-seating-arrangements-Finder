import pdfplumber
import re

filepath = "pdfs/12-01-2026_FN-THEORY.pdf"

print(f"Testing PDF: {filepath}")
print("=" * 80)

with pdfplumber.open(filepath) as pdf:
    print(f"Total pages: {len(pdf.pages)}\n")
    
    for page_num, page in enumerate(pdf.pages[:2]):  # Test first 2 pages
        print(f"\n--- PAGE {page_num + 1} ---")
        
        tables = page.extract_tables()
        print(f"Tables found: {len(tables)}")
        
        for table_idx, table in enumerate(tables):
            print(f"\nTable {table_idx + 1}:")
            print(f"  Rows: {len(table)}")
            
            # Print first few rows
            for i, row in enumerate(table[:5]):
                print(f"  Row {i}: {row}")
            
            # Check for header
            for idx, row in enumerate(table[:5]):
                if row and any(cell and ('Reg' in str(cell) or 'Position' in str(cell) or 'Hall' in str(cell)) for cell in row):
                    print(f"\n  HEADER FOUND at row {idx}: {row}")
                    break
