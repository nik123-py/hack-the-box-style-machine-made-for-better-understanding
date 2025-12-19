const express = require('express');
const bodyParser = require('body-parser');
const cookieParser = require('cookie-parser');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 3000;

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Routes
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const webhookRoutes = require('./routes/webhook');

app.use('/auth', authRoutes);
app.use('/admin', adminRoutes);
app.use('/webhook', webhookRoutes);

// Home page
app.get('/', (req, res) => {
  res.render('index');
});

// Start server (listen on all interfaces for HTB)
app.listen(PORT, '0.0.0.0', () => {
  console.log(`[+] Courier CI/CD Platform running on port ${PORT}`);
});

