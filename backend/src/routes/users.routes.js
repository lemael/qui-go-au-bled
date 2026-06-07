const express = require('express');
const cloudinary = require('cloudinary').v2;
const multer = require('multer');
const pool = require('../db');
const auth = require('../middleware/auth');
const { formatUser } = require('./auth.routes');

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 5 * 1024 * 1024 } });

if (process.env.CLOUDINARY_CLOUD_NAME) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
}

// GET /api/users/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ message: 'Utilisateur introuvable' });
    res.json({ user: formatUser(result.rows[0]) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/users/profile
router.patch('/profile', auth, upload.single('photo'), async (req, res) => {
  try {
    const { fullName, phone, address } = req.body;
    let photoUrl = null;

    if (req.file && process.env.CLOUDINARY_CLOUD_NAME) {
      const uploadResult = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: 'profile_photos', public_id: req.userId, overwrite: true },
          (error, result) => (error ? reject(error) : resolve(result))
        );
        stream.end(req.file.buffer);
      });
      photoUrl = uploadResult.secure_url;
    }

    const updates = [];
    const values = [];
    let i = 1;
    if (fullName) { updates.push(`full_name = $${i++}`); values.push(fullName.trim()); }
    if (phone !== undefined) { updates.push(`phone = $${i++}`); values.push(phone); }
    if (address !== undefined) { updates.push(`address = $${i++}`); values.push(address); }
    if (photoUrl) { updates.push(`photo_url = $${i++}`); values.push(photoUrl); }
    updates.push('updated_at = NOW()');
    values.push(req.userId);

    if (updates.length === 1) {
      const result = await pool.query('SELECT * FROM users WHERE id = $1', [req.userId]);
      return res.json({ user: formatUser(result.rows[0]) });
    }

    const result = await pool.query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = $${i} RETURNING *`,
      values
    );
    res.json({ user: formatUser(result.rows[0]) });
  } catch (err) {
    console.error('Profile update error:', err.message);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/users/fcm-token
router.patch('/fcm-token', auth, async (req, res) => {
  try {
    await pool.query(
      'UPDATE users SET fcm_token = $1, updated_at = NOW() WHERE id = $2',
      [req.body.token, req.userId]
    );
    res.json({ message: 'Token FCM mis à jour' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;
