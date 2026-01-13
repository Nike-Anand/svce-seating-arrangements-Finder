// API Configuration - automatically detects environment
const API_BASE_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:10000'
    : ''; // Empty string uses same domain (served by Flask)

// DOM Elements
const registerInput = document.getElementById('registerInput');
const searchBtn = document.getElementById('searchBtn');
const refreshBtn = document.getElementById('refreshBtn');
const loadingIndicator = document.getElementById('loadingIndicator');
const resultsSection = document.getElementById('resultsSection');
const resultsContainer = document.getElementById('resultsContainer');
const noResults = document.getElementById('noResults');
const errorMessage = document.getElementById('errorMessage');
const lastUpdated = document.getElementById('lastUpdated');
const totalRecords = document.getElementById('totalRecords');
const statsCard = document.getElementById('statsCard');

// Load stats on page load
loadStats();

// Event Listeners
searchBtn.addEventListener('click', performSearch);
registerInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        performSearch();
    }
});
refreshBtn.addEventListener('click', refreshData);

async function loadStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/stats`);
        const data = await response.json();

        if (data.last_updated) {
            const date = new Date(data.last_updated);
            lastUpdated.textContent = date.toLocaleString();
        } else {
            lastUpdated.textContent = 'No data yet';
        }

        totalRecords.textContent = data.total_entries || 0;
    } catch (error) {
        console.error('Error loading stats:', error);
        lastUpdated.textContent = 'Error loading';
        totalRecords.textContent = '-';

        // Show a subtle message if no data is available
        if (error.message.includes('404')) {
            showError('No data available yet. Click "Refresh Data" to fetch the latest seating arrangements.');
        }
    }
}

async function performSearch() {
    const registerNo = registerInput.value.trim();

    if (!registerNo) {
        showError('Please enter a register number');
        return;
    }

    // Hide previous results
    hideAll();
    loadingIndicator.style.display = 'flex';

    try {
        const response = await fetch(`${API_BASE_URL}/api/search?register_no=${encodeURIComponent(registerNo)}`);
        const data = await response.json();

        loadingIndicator.style.display = 'none';

        if (data.error) {
            showError(data.error);
            return;
        }

        if (data.found && data.results.length > 0) {
            displayResults(data.results);
        } else {
            noResults.style.display = 'flex';
        }
    } catch (error) {
        loadingIndicator.style.display = 'none';
        showError('Error connecting to server. Please make sure the backend is running.');
        console.error('Search error:', error);
    }
}

function displayResults(results) {
    resultsSection.style.display = 'block';
    resultsContainer.innerHTML = '';

    results.forEach((result, index) => {
        const card = document.createElement('div');
        card.className = 'result-card';
        card.style.animationDelay = `${index * 0.1}s`;

        card.innerHTML = `
            <div class="result-header">
                <span class="register-badge">${result.register_no}</span>
                <span class="exam-badge">${result.exam_date} - ${result.session}</span>
            </div>
            <div class="result-details">
                <div class="detail-item">
                    <span class="detail-label">Hall/Room</span>
                    <span class="detail-value">${result.hall || 'N/A'}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Seat Number</span>
                    <span class="detail-value">${result.seat || 'N/A'}</span>
                </div>
            </div>
            ${result.pdf_url ? `
                <div class="pdf-link">
                    <a href="${result.pdf_url}" target="_blank">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                            <polyline points="14 2 14 8 20 8"></polyline>
                        </svg>
                        View Full PDF
                    </a>
                </div>
            ` : ''}
        `;

        resultsContainer.appendChild(card);
    });
}

async function refreshData() {
    refreshBtn.disabled = true;
    refreshBtn.innerHTML = `
        <div class="spinner" style="width: 20px; height: 20px; border-width: 2px;"></div>
        Refreshing...
    `;

    hideAll();
    loadingIndicator.style.display = 'flex';
    loadingIndicator.querySelector('p').textContent = 'Fetching latest data from SVCE website...';

    try {
        const response = await fetch(`${API_BASE_URL}/api/refresh`, {
            method: 'POST'
        });
        const data = await response.json();

        loadingIndicator.style.display = 'none';

        if (data.success) {
            showSuccess(`Successfully updated ${data.total_entries} entries!`);
            loadStats();
        } else {
            showError(data.error || 'Failed to refresh data');
        }
    } catch (error) {
        loadingIndicator.style.display = 'none';
        showError('Error connecting to server. Please make sure the backend is running.');
        console.error('Refresh error:', error);
    } finally {
        refreshBtn.disabled = false;
        refreshBtn.innerHTML = `
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/>
            </svg>
            Refresh Data
        `;
        loadingIndicator.querySelector('p').textContent = 'Searching...';
    }
}

function showError(message) {
    errorMessage.textContent = message;
    errorMessage.style.display = 'block';
    setTimeout(() => {
        errorMessage.style.display = 'none';
    }, 5000);
}

function showSuccess(message) {
    errorMessage.style.background = 'linear-gradient(135deg, rgba(16, 185, 129, 0.2) 0%, rgba(16, 185, 129, 0.1) 100%)';
    errorMessage.style.borderColor = 'var(--success)';
    errorMessage.style.color = 'var(--success)';
    errorMessage.textContent = message;
    errorMessage.style.display = 'block';
    setTimeout(() => {
        errorMessage.style.display = 'none';
        errorMessage.style.background = '';
        errorMessage.style.borderColor = '';
        errorMessage.style.color = '';
    }, 5000);
}

function hideAll() {
    resultsSection.style.display = 'none';
    noResults.style.display = 'none';
    errorMessage.style.display = 'none';
}
