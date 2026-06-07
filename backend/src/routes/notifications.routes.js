const express = require('express');
const { v4: uuidv4 } = require('uuid');
const pool = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

function formatNotif(row) {
  return {
    id: row.id,
    userId: row.user_id,
    title: row.title,
    body: row.body,
    type: row.type,
    relatedId: row.related_id || null,
    isRead: row.is_read,
    createdAt: row.created_at.toISOString(),
  };
}

// GET /api/notifications
router.get('/', auth, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM notifications WHERE user_id=$1 ORDER BY created_at DESC LIMIT 50',
      [req.userId]
    );
    res.json({ notifications: result.rows.map(formatNotif) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/notifications/read-all  (doit être AVANT /:id/read)
router.patch('/read-all', auth, async (req, res) => {
  try {
    await pool.query('UPDATE notifications SET is_read=true WHERE user_id=$1', [req.userId]);
    res.json({ message: 'Tout marqué comme lu' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/notifications/:id/read
router.patch('/:id/read', auth, async (req, res) => {
  try {
    await pool.query(
      'UPDATE notifications SET is_read=true WHERE id=$1 AND user_id=$2',
      [req.params.id, req.userId]
    );
    res.json({ message: 'Lu' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;
