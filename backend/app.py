from flask import Flask, jsonify, request, render_template
from flask_cors import CORS
import requests
from bs4 import BeautifulSoup
import pdfplumber
import re
import json
import os
from datetime import datetime

# Configure Flask to serve frontend from the frontend directory
app = Flask(__name__, 
            template_folder='../frontend',
            static_folder='../frontend',
            static_url_path='')
CORS(app)

# Get the directory where this script is located
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Directory to store downloaded PDFs
PDF_DIR = os.path.join(BASE_DIR, "pdfs")
DATA_FILE = os.path.join(BASE_DIR, "seating_data.json")

if not os.path.exists(PDF_DIR):
    os.makedirs(PDF_DIR)

def scrape_pdf_links():
    """Scrape the SVCE website for PDF links"""
    try:
        # The actual page with PDF links is in an iframe
        iframe_url = "https://www.svce.ac.in/coe-ims/files.php"
        response = requests.get(iframe_url, timeout=10)
        soup = BeautifulSoup(response.content, 'html.parser')
        
        pdf_links = []
        # Find all table rows (skip header)
        rows = soup.find_all('tr')[1:]  # Skip the header row
        
        for row in rows:
            cells = row.find_all('td')
            if len(cells) >= 4:  # S.No, Exam Date, FN/AN, View
                # Extract data from cells
                exam_date = cells[1].get_text(strip=True)
                session = cells[2].get_text(strip=True)
                
                # Find the link in the last cell
                link = cells[3].find('a')
                if link and link.get('href'):
                    href = link['href']
                    
                    # Construct full URL
                    if href.startswith('http'):
                        full_url = href
                    elif href.startswith('/'):
                        full_url = f"https://www.svce.ac.in{href}"
                    else:
                        # Relative path like "malarup/FN-THEORY_1767841222.pdf"
                        full_url = f"https://www.svce.ac.in/coe-ims/{href}"
                    
                    pdf_links.append({
                        'url': full_url,
                        'date': exam_date,
                        'session': session
                    })
        
        return pdf_links
    except Exception as e:
        print(f"Error scraping PDF links: {e}")
        import traceback
        traceback.print_exc()
        return []

def download_pdf(url, filename):
    """Download a PDF file"""
    try:
        response = requests.get(url, timeout=30)
        filepath = os.path.join(PDF_DIR, filename)
        with open(filepath, 'wb') as f:
            f.write(response.content)
        return filepath
    except Exception as e:
        print(f"Error downloading PDF {url}: {e}")
        return None

def parse_pdf(filepath):
    """Parse PDF and extract seating arrangement data"""
    seating_data = []
    
    try:
        with pdfplumber.open(filepath) as pdf:
            for page_num, page in enumerate(pdf.pages):
                # Extract tables from the page
                tables = page.extract_tables()
                
                if not tables:
                    print(f"  No tables found on page {page_num + 1}")
                    continue
                
                for table_idx, table in enumerate(tables):
                    if not table or len(table) < 2:  # Need at least header + 1 row
                        continue
                    
                    # Find header row (look for "Reg. No." or similar)
                    header_row = None
                    data_start_idx = 0
                    
                    for idx, row in enumerate(table[:5]):  # Check first 5 rows for header
                        if row and any(cell and ('Reg' in str(cell) or 'Position' in str(cell) or 'Hall' in str(cell)) for cell in row):
                            header_row = [str(cell).strip() if cell else '' for cell in row]
                            data_start_idx = idx + 1
                            break
                    
                    if not header_row:
                        print(f"  No header found in table {table_idx + 1} on page {page_num + 1}")
                        continue
                    
                    # Find column indices
                    reg_col = None
                    position_col = None
                    hall_col = None
                    hall_desc_col = None
                    
                    for i, header in enumerate(header_row):
                        header_lower = header.lower()
                        if 'reg' in header_lower and 'no' in header_lower:
                            reg_col = i
                        elif 'position' in header_lower:
                            position_col = i
                        elif 'hall' in header_lower and 'no' in header_lower:
                            hall_col = i
                        elif 'hall' in header_lower and 'desc' in header_lower:
                            hall_desc_col = i
                    
                    print(f"  Found columns - Reg: {reg_col}, Position: {position_col}, Hall: {hall_col}, Desc: {hall_desc_col}")
                    
                    if reg_col is None:
                        print(f"  Could not find register number column")
                        continue
                    
                    # Extract data rows
                    for row_idx in range(data_start_idx, len(table)):
                        row = table[row_idx]
                        if not row or len(row) <= reg_col:
                            continue
                        
                        reg_no = str(row[reg_col]).strip() if row[reg_col] else None
                        
                        # Validate register number (should be digits, typically 9-13 characters)
                        if not reg_no or not re.match(r'^\d{9,13}$', reg_no):
                            continue
                        
                        # Extract position (seat)
                        position = str(row[position_col]).strip() if position_col is not None and len(row) > position_col and row[position_col] else "N/A"
                        
                        # Extract hall number
                        hall_no = str(row[hall_col]).strip() if hall_col is not None and len(row) > hall_col and row[hall_col] else "N/A"
                        
                        # Extract hall description
                        hall_desc = str(row[hall_desc_col]).strip() if hall_desc_col is not None and len(row) > hall_desc_col and row[hall_desc_col] else "N/A"
                        
                        # Combine hall info
                        if hall_no != "N/A" and hall_desc != "N/A":
                            hall_info = f"{hall_no} - {hall_desc}"
                        elif hall_no != "N/A":
                            hall_info = hall_no
                        elif hall_desc != "N/A":
                            hall_info = hall_desc
                        else:
                            hall_info = "N/A"
                        
                        seating_data.append({
                            'register_no': reg_no,
                            'hall': hall_info,
                            'seat': position,
                            'raw_data': f"Hall: {hall_no}, Position: {position}, Description: {hall_desc}"
                        })
    
    except Exception as e:
        print(f"Error parsing PDF {filepath}: {e}")
        import traceback
        traceback.print_exc()
    
    return seating_data

def update_seating_data():
    """Scrape, download, and parse all PDFs to update seating data"""
    all_data = []
    
    print("Scraping PDF links...")
    pdf_links = scrape_pdf_links()
    print(f"Found {len(pdf_links)} PDF files")
    
    for idx, pdf_info in enumerate(pdf_links):
        print(f"Processing PDF {idx + 1}/{len(pdf_links)}: {pdf_info['date']} - {pdf_info['session']}")
        
        # Download PDF
        filename = f"{pdf_info['date'].replace('/', '-')}_{pdf_info['session']}.pdf"
        filepath = download_pdf(pdf_info['url'], filename)
        
        if filepath:
            # Parse PDF
            seating_data = parse_pdf(filepath)
            
            # Add metadata
            for entry in seating_data:
                entry['exam_date'] = pdf_info['date']
                entry['session'] = pdf_info['session']
                entry['pdf_url'] = pdf_info['url']
            
            all_data.extend(seating_data)
            print(f"  Extracted {len(seating_data)} entries")
    
    # Save to JSON file
    with open(DATA_FILE, 'w') as f:
        json.dump({
            'last_updated': datetime.now().isoformat(),
            'total_entries': len(all_data),
            'data': all_data
        }, f, indent=2)
    
    print(f"Total entries saved: {len(all_data)}")
    return all_data

@app.route('/api/search', methods=['GET'])
def search_register():
    """Search for a register number"""
    register_no = request.args.get('register_no', '').strip()
    
    if not register_no:
        return jsonify({'error': 'Register number is required'}), 400
    
    # Load data
    if not os.path.exists(DATA_FILE):
        return jsonify({'error': 'No data available. Please refresh data first.'}), 404
    
    with open(DATA_FILE, 'r') as f:
        data = json.load(f)
    
    # Search for register number
    results = [entry for entry in data['data'] if register_no in entry['register_no']]
    
    return jsonify({
        'register_no': register_no,
        'found': len(results) > 0,
        'results': results,
        'last_updated': data.get('last_updated', 'Unknown')
    })

@app.route('/api/refresh', methods=['POST'])
def refresh_data():
    """Refresh seating data by scraping and parsing PDFs"""
    try:
        all_data = update_seating_data()
        return jsonify({
            'success': True,
            'message': f'Successfully updated {len(all_data)} entries',
            'total_entries': len(all_data)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/stats', methods=['GET'])
def get_stats():
    """Get statistics about the data"""
    if not os.path.exists(DATA_FILE):
        return jsonify({
            'last_updated': None,
            'total_entries': 0,
            'available': False,
            'message': 'No data available yet. Click "Refresh Data" to fetch seating arrangements.'
        })
    
    with open(DATA_FILE, 'r') as f:
        data = json.load(f)
    
    return jsonify({
        'last_updated': data.get('last_updated', 'Unknown'),
        'total_entries': data.get('total_entries', 0),
        'available': True
    })

@app.route('/')
def index():
    """Serve the frontend HTML page"""
    return render_template('index.html')

@app.route('/api')
def api_info():
    """API information endpoint"""
    return jsonify({
        'message': 'SVCE Seating Arrangement API',
        'endpoints': {
            '/api/search?register_no=<number>': 'Search for a register number',
            '/api/refresh': 'Refresh data from website (POST)',
            '/api/stats': 'Get data statistics'
        }
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 10000))
    app.run(host='0.0.0.0', port=port, debug=False)
