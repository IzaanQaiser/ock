require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3001;

// Increase payload limit for base64 images
app.use(express.json({ limit: '50mb' }));
app.use(cors());

// Overshoot API configuration
const OVERSHOOT_API_URL = 'https://api.overshoot.ai';
const OVERSHOOT_API_KEY = process.env.OVERSHOOT_API_KEY || '';

// Simple logging middleware
app.use((req, res, next) => {
    if (req.path !== '/health') {
        console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    }
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
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

// ========================================
// SCREENSHOT ANALYSIS ENDPOINT
// ========================================
app.post('/api/analyze', async (req, res) => {
    const { image, prompt } = req.body;

    if (!image) {
        return res.status(400).json({
            success: false,
            error: 'No image provided'
        });
    }

    console.log('');
    console.log('🖼️  ═══════════════════════════════════════');
    console.log('   SCREENSHOT RECEIVED FOR ANALYSIS');
    console.log('═══════════════════════════════════════');
    console.log(`Prompt: ${prompt?.substring(0, 100) || 'default'}...`);
    console.log(`Image size: ${Math.round(image.length / 1024)} KB`);
    console.log(`Time: ${new Date().toISOString()}`);
    console.log('═══════════════════════════════════════');

    try {
        // Save the screenshot locally for debugging
        const screenshotDir = path.join(__dirname, 'screenshots');
        if (!fs.existsSync(screenshotDir)) {
            fs.mkdirSync(screenshotDir);
        }
        const filename = `screenshot_${Date.now()}.jpg`;
        const filepath = path.join(screenshotDir, filename);
        fs.writeFileSync(filepath, Buffer.from(image, 'base64'));
        console.log(`📁 Screenshot saved: ${filename}`);

        // TODO: Integrate with Overshoot API
        // For now, we'll simulate the response and log that we received the screenshot
        // The Overshoot SDK is browser-based, so we need to either:
        // 1. Use their REST API directly (if available for single images)
        // 2. Set up a browser automation to process images

        // Placeholder response - replace with actual Overshoot integration
        const analysisResult = {
            success: true,
            message: 'Screenshot received and saved. Overshoot integration pending.',
            filename: filename,
            prompt: prompt,
            timestamp: new Date().toISOString()
        };

        console.log('');
        console.log('✅ Screenshot processed successfully');
        console.log('');

        res.json({
            success: true,
            result: `Screenshot captured and saved as ${filename}. Ready for Overshoot analysis.`,
            filename: filename
        });

    } catch (error) {
        console.error('❌ Error processing screenshot:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
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
    console.log(`  GET  /health      - Health check`);
    console.log(`  POST /api/log     - Log a message`);
    console.log(`  POST /api/analyze - Analyze screenshot with Overshoot`);
    console.log('');
    if (!OVERSHOOT_API_KEY) {
        console.log('⚠️  OVERSHOOT_API_KEY not set. Set it with:');
        console.log('   export OVERSHOOT_API_KEY=ovs_07eb8444c29d46996f90619a628521c2');
        console.log('');
    }
    console.log('Waiting for screenshots from ock app...');
    console.log('Hold Option key in the app to trigger screenshot capture.');
    console.log('');
});
