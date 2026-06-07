const express = require('express');
const pool = require('../db');
const adminAuth = require('../middleware/adminAuth');
const { formatUser } = require('./auth.routes');

const router = express.Router();

const AD_SELECT = `
  SELECT a.*, u.full_name as transporter_name, u.photo_url as transporter_photo_url,
         u.average_rating as transporter_rating, u.total_reviews as transporter_reviews
  FROM transport_ads a
  JOIN users u ON a.transporter_id = u.id
`;

function formatAd(row) {
  return {
    id: row.id,
    transporterId: row.transporter_id,
    transporterName: row.transporter_name,
    transporterPhotoUrl: row.transporter_photo_url || null,
    transporterRating: parseFloat(row.transporter_rating) || 0.0,
    transporterReviews: parseInt(row.transporter_reviews) || 0,
    departureCity: row.departure_city,
    arrivalCity: row.arrival_city,
    flightDate: row.flight_date instanceof Date ? row.flight_date.toISOString() : String(row.flight_date),
    flightTime: row.flight_time || '',
    maxWeightKg: parseFloat(row.max_weight_kg),
    pricePerKg: parseFloat(row.price_per_kg),
    description: row.description || '',
    status: row.status,
    totalPackagesCarried: parseInt(row.total_packages_carried) || 0,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

// GET /api/admin/users — liste tous les utilisateurs
router.get('/users', adminAuth, async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;
    const result = await pool.query(
      'SELECT * FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2',
      [parseInt(limit), parseInt(offset)]
    );
    const total = await pool.query('SELECT COUNT(*) FROM users');
    res.json({
      users: result.rows.map(formatUser),
      total: parseInt(total.rows[0].count),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/admin/ads/pending — annonces en attente de validation
router.get('/ads/pending', adminAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `${AD_SELECT} WHERE a.status = 'pending' ORDER BY a.created_at DESC`
    );
    res.json({ ads: result.rows.map(formatAd) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/admin/ads — toutes les annonces
router.get('/ads', adminAuth, async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;
    let query = `${AD_SELECT}`;
    const values = [];
    let i = 1;
    if (status) { query += ` WHERE a.status = $${i++}`; values.push(status); }
    query += ` ORDER BY a.created_at DESC LIMIT $${i++} OFFSET $${i++}`;
    values.push(parseInt(limit), parseInt(offset));
    const result = await pool.query(query, values);
    const countResult = await pool.query(
      `SELECT COUNT(*) FROM transport_ads${status ? ` WHERE status = $1` : ''}`,
      status ? [status] : []
    );
    res.json({ ads: result.rows.map(formatAd), total: parseInt(countResult.rows[0].count) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/admin/ads/:id/approve — approuver une annonce
router.patch('/ads/:id/approve', adminAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE transport_ads SET status='active', updated_at=NOW() WHERE id=$1 RETURNING id`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'Annonce introuvable' });
    res.json({ message: 'Annonce approuvée et publiée' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/admin/ads/:id/reject — rejeter une annonce
router.patch('/ads/:id/reject', adminAuth, async (req, res) => {
  try {
    const { reason } = req.body;
    const result = await pool.query(
      `UPDATE transport_ads SET status='rejected', updated_at=NOW() WHERE id=$1 RETURNING id`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'Annonce introuvable' });
    res.json({ message: 'Annonce rejetée', reason: reason || '' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// DELETE /api/admin/users/:id — supprimer un utilisateur
router.delete('/users/:id', adminAuth, async (req, res) => {
  try {
    if (req.params.id === req.userId) {
      return res.status(400).json({ message: 'Impossible de supprimer son propre compte' });
    }
    await pool.query('DELETE FROM users WHERE id=$1', [req.params.id]);
    res.json({ message: 'Utilisateur supprimé' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/admin/stats — statistiques générales
router.get('/stats', adminAuth, async (req, res) => {
  try {
    const [users, ads, pendingAds, orders] = await Promise.all([
      pool.query('SELECT COUNT(*) FROM users WHERE role != $1', ['admin']),
      pool.query('SELECT COUNT(*) FROM transport_ads WHERE status = $1', ['active']),
      pool.query('SELECT COUNT(*) FROM transport_ads WHERE status = $1', ['pending']),
      pool.query('SELECT COUNT(*) FROM transport_orders'),
    ]);
    res.json({
      totalUsers: parseInt(users.rows[0].count),
      activeAds: parseInt(ads.rows[0].count),
      pendingAds: parseInt(pendingAds.rows[0].count),
      totalOrders: parseInt(orders.rows[0].count),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;
