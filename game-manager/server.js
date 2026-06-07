
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const GAME_MANAGER_DIR = path.join(__dirname, 'game-manager');
const CONFIG_FILE = path.join(GAME_MANAGER_DIR, 'config', 'config.json');

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;
    
    // Handle static files
    if (pathname === '/') {
        serveFile(res, path.join(GAME_MANAGER_DIR, 'index.html'), 'text/html');
    } else if (pathname.startsWith('/config/')) {
        serveFile(res, path.join(GAME_MANAGER_DIR, pathname), 'application/json');
    } else if (pathname === '/add-game' && req.method === 'POST') {
        handleAddGame(req, res);
    } else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
    }
});

function serveFile(res, filePath, contentType) {
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end('Internal Server Error');
        } else {
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(data);
        }
    });
}

function handleAddGame(req, res) {
    let body = '';
    
    req.on('data', chunk => {
        body += chunk.toString();
    });
    
    req.on('end', () => {
        try {
            const game = JSON.parse(body);
            
            // Read current config
            fs.readFile(CONFIG_FILE, (err, data) => {
                if (err) {
                    res.writeHead(500, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ success: false, message: 'Error reading config' }));
                    return;
                }
                
                const config = JSON.parse(data);
                config.custom_games.push(game);
                
                // Write updated config
                fs.writeFile(CONFIG_FILE, JSON.stringify(config, null, 2), (err) => {
                    if (err) {
                        res.writeHead(500, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ success: false, message: 'Error saving config' }));
                    } else {
                        res.writeHead(200, { 'Content-Type': 'application/json' });
                        res.end(JSON.stringify({ success: true }));
                    }
                });
            });
        } catch (error) {
            res.writeHead(400, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: false, message: 'Invalid request body' }));
        }
    });
}

const PORT = 3000;
server.listen(PORT, () => {
    console.log(`Game Manager server running at http://localhost:${PORT}`);
});
