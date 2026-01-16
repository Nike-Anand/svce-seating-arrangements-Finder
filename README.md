"# SVCE Seating Arrangement Finder
##
A web application to help students find their seating arrangements for exams at Sri Venkateswara College of Engineering (SVCE). The app automatically scrapes the SVCE website, parses PDF seating arrangements, and provides a clean search interface.

## Features

- 🔍 **Quick Search**: Search by register number to find your seat
- 📄 **PDF Parsing**: Automatically extracts data from official SVCE PDFs
- 🔄 **Auto Refresh**: Update data with latest seating arrangements
- 📊 **Statistics**: View total records and last update time
- 🎨 **Modern UI**: Clean, responsive interface with smooth animations

## Tech Stack

- **Backend**: Flask (Python)
- **Frontend**: HTML, CSS, JavaScript
- **PDF Processing**: pdfplumber
- **Web Scraping**: BeautifulSoup4, Requests

## Deployment on Render

### Prerequisites
- GitHub account
- Render account (free tier works fine)

### Steps

1. **Push to GitHub** (if not already done)
   ```bash
   git add .
   git commit -m "Prepare for Render deployment"
   git push origin main
   ```

2. **Deploy on Render**
   - Go to [Render Dashboard](https://dashboard.render.com/)
   - Click **New** → **Web Service**
   - Choose **Build and deploy from a Git repository**
   - Connect your GitHub repository
   - Configure the service:
     - **Name**: `svce-seating-finder` (or your preferred name)
     - **Region**: Choose closest to you
     - **Branch**: `main`
     - **Runtime**: `Python 3`
     - **Build Command**: `pip install -r requirements.txt`
     - **Start Command**: `gunicorn backend.app:app`
   - Choose **Free** instance type
   - Click **Create Web Service**

3. **Update Frontend URL**
   - After deployment, Render will give you a URL like `https://your-app-name.onrender.com`
   - Update `frontend/script.js` line 4 with your actual Render URL
   - Commit and push the change

4. **Access Your App**
   - Backend API: `https://your-app-name.onrender.com`
   - Frontend: Open `frontend/index.html` in a browser or deploy separately

### Important Notes

- **Free Tier**: Services spin down after 15 minutes of inactivity. First request after spin-down will be slow (~30 seconds).
- **Port Binding**: The app automatically binds to Render's PORT environment variable (default: 10000).
- **CORS**: Already configured to allow cross-origin requests.

## Local Development

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Nike-Anand/svce-seating-arrangements-Finder.git
   cd svce-seating-arrangements-Finder
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the backend**
   ```bash
   python backend/app.py
   ```
   The API will be available at `http://localhost:10000`

4. **Open the frontend**
   - Open `frontend/index.html` in your browser
   - Or use a local server:
     ```bash
     cd frontend
     python -m http.server 8000
     ```
   - Then visit `http://localhost:8000`

## Usage

1. **Refresh Data**: Click "Refresh Data" to fetch the latest seating arrangements from SVCE website
2. **Search**: Enter your register number and click "Search" or press Enter
3. **View Results**: See your hall, seat number, and exam details
4. **PDF Link**: Click "View Full PDF" to see the original PDF

## API Endpoints

- `GET /` - API information
- `GET /api/search?register_no=<number>` - Search for a register number
- `POST /api/refresh` - Refresh data from SVCE website
- `GET /api/stats` - Get statistics (last updated, total entries)

## Project Structure

```
svce-seating-arrangements-Finder/
├── backend/
│   ├── app.py              # Flask application
│   ├── seating_data.json   # Cached seating data
│   └── test_parser.py      # PDF parser testing
├── frontend/
│   ├── index.html          # Main UI
│   ├── script.js           # Frontend logic
│   └── style.css           # Styling
├── requirements.txt        # Python dependencies
├── render.yaml            # Render deployment config
└── README.md              # This file
```

## Troubleshooting

### Backend not responding
- Check if the backend is running
- Verify the PORT environment variable is set correctly
- Check Render logs for errors

### No data found
- Click "Refresh Data" to fetch latest data from SVCE
- Ensure the SVCE website is accessible
- Check backend logs for scraping errors

### CORS errors
- Ensure flask-cors is installed
- Verify CORS is enabled in `app.py`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License." 
