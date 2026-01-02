// CANARY_STRING: polyglot_dep_graph_2025_v1
const jwt = require('./jwt-service');
const express = require('express');

class LoginController {
    async login(req, res) {
        const token = await jwt.generateToken(req.body);
        res.json({ token });
    }
}

module.exports = LoginController;