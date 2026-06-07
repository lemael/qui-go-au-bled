const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const pool = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

function generateToken(userId, email) {
  return jwt.sign({ userId, email }, process.env.JWT_SECRET, { expiresIn: '30d' });
}

function formatUser(row) {
  return {
    id: row.id,
    fullName: row.full_name,
    email: row.email,
    phone: row.phone || '',
    address: row.address || '',
    photoUrl: row.photo_url || null,
    role: row.role,
    averageRating: parseFloat(row.average_rating) || 0.0,
    totalReviews: parseInt(row.total_reviews) || 0,
    fcmToken: row.fcm_token || null,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { email, password, fullName, phone, address } = req.body;
  if (!email || !password || !fullName) {
    return res.status(400).json({ message: 'Champs requis manquants' });
  }
  try {
    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [email.toLowerCase().trim()]);
    if (existing.rows.length > 0) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé' });
    }
    const passwordHash = await bcrypt.hash(password, 10);
    const id = uuidv4();
    const result = await pool.query(
      `INSERT INTO users (id, full_name, email, phone, address, password_hash, role)
       VALUES ($1, $2, $3, $4, $5, $6, 'both') RETURNING *`,
      [id, fullName.trim(), email.toLowerCase().trim(), phone || '', address || '', passwordHash]
    );
    const token = generateToken(result.rows[0].id, result.rows[0].email);
    res.status(201).json({ token, user: formatUser(result.rows[0]) });
  } catch (err) {
    console.error('Register error:', err.message);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Email et mot de passe requis' });
  }
  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email.toLowerCase().trim()]);
    if (result.rows.length === 0) {
      return res.status(401).json({ message: 'Aucun compte trouvé avec cet email' });
    }
    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ message: 'Mot de passe incorrect' });
    }
    const token = generateToken(user.id, user.email);
    res.json({ token, user: formatUser(user) });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/auth/me
router.get('/me', auth, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.userId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Utilisateur introuvable' });
    }
    res.json({ user: formatUser(result.rows[0]) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// POST /api/auth/reset-password
router.post('/reset-password', async (req, res) => {
  // TODO: envoyer un vrai email de réinitialisation
  res.json({ message: 'Si cet email existe, un lien de réinitialisation a été envoyé' });
});

module.exports = router;
module.exports.formatUser = formatUser;
