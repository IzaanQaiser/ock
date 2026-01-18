const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Simple logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    console.log('📍 Health check received');
    res.json({ status: 'ok', message: 'ock backend is running' });
});

// Test message endpoint - logs messages from the app
app.post('/api/log', (req, res) => {
    const { message, source } = req.body;
    
    console.log('');
    console.log('═══════════════════════════════════════');
    console.log('📨 MESSAGE RECEIVED FROM APP');
    console.log('═══════════════════════════════════════');
    console.log(`Source: ${source || 'unknown'}`);
    console.log(`Message: ${message}`);
    console.log(`Time: ${new Date().toISOString()}`);
    console.log('═══════════════════════════════════════');
    console.log('');
    
    res.json({ 
        success: true, 
        received: message,
        timestamp: new Date().toISOString()
    });
});

// Generic test endpoint
app.post('/api/test', (req, res) => {
    console.log('🧪 Test endpoint hit with body:', JSON.stringify(req.body, null, 2));
    res.json({ success: true, echo: req.body });
});

// Start server
app.listen(PORT, () => {
    console.log('');
    console.log('🚀 ═══════════════════════════════════════');
    console.log(`   ock Backend Server`);
    console.log(`   Running on http://localhost:${PORT}`);
    console.log('   ═══════════════════════════════════════');
    console.log('');
    console.log('Available endpoints:');
    console.log(`  GET  /health     - Health check`);
    console.log(`  POST /api/log    - Log a message from the app`);
    console.log(`  POST /api/test   - Echo test endpoint`);
    console.log('');
    console.log('Waiting for messages from ock app...');
    console.log('');
});
