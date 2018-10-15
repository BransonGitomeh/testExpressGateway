const express = require('express');
const app = express();

const {
  HOST="0.0.0.0",
  PORT=8080
} = process.env

app.get('/', (req, res) => {
    res.send('Welcome, gateway is up');
});

app.get('/login', (req, res) => {
    res.send('Welcome, gateway is up');
    // talk to the auth services
    // track this login
    // send user email to know they logged in
});

app.listen(PORT,HOST, () => console.log(`Gateway listening on port ${HOST}:${PORT}!`));
