# Memorio AI - Obituary Generator

A beautiful, multi-step form for generating personalized obituaries with AI assistance.

## Features

- Multi-step form with smooth transitions
- File upload functionality
- AI-powered obituary generation
- Typewriter effect for obituary display
- Responsive design
- Form validation and error handling

## Technology Stack

- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Styling**: Webflow CSS framework
- **Animations**: Custom CSS animations and transitions
- **File Upload**: UploadCare integration
- **Backend**: N8N webhooks for AI processing

## Deployment

This site is designed to be deployed on Netlify with a custom domain.

### Environment Variables

For production deployment, ensure these endpoints are configured:
- `MEMORIO_INTAKE_WEBHOOK`: N8N webhook for obituary generation
- `MEMORIO_EMAIL_WEBHOOK`: N8N webhook for email sending

### Domain Requirements

The N8N webhooks are configured to accept requests from:
- `https://www.memorio.ai`
- `https://memorio.ai`

## Local Development

To run locally with mock data:

1. Start the Python HTTP server:
   ```bash
   python3 -m http.server 8000
   ```

2. Start the mock server:
   ```bash
   node mock-server.js
   ```

3. Open `http://localhost:8000`

## File Structure

```
memorio-ai/
├── index.html              # Main HTML file
├── css/                    # Stylesheets
│   ├── webflow.css
│   ├── normalize.css
│   └── memorio-forms.webflow.css
├── js/                     # JavaScript files
│   └── webflow.js
├── images/                 # Image assets
├── fonts/                  # Font files
├── mock-server.js          # Local development server
└── README.md               # This file
```

## License

Private project for Memorio AI.
