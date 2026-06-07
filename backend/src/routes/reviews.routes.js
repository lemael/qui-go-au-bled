const express = require('express');
const { v4: uuidv4 } = require('uuid');
const pool = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

function formatReview(row) {
  return {
    id: row.id,
    orderId: row.order_id,
    orderNumber: row.order_number,
    transporterId: row.transporter_id,
    transporterName: row.transporter_name || '',
    clientId: row.client_id,
    clientName: row.client_name || '',
    clientPhotoUrl: row.client_photo_url || null,
    rating: parseFloat(row.rating),
    comment: row.comment || '',
    punctuality: parseFloat(row.punctuality) || 0,
    communication: parseFloat(row.communication) || 0,
    packageCondition: parseFloat(row.package_condition) || 0,
    reliability: parseFloat(row.reliability) || 0,
    createdAt: row.created_at.toISOString(),
  };
}

// GET /api/reviews/transporter/:transporterId
router.get('/transporter/:transporterId', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT r.*, uc.full_name as client_name, uc.photo_url as client_photo_url,
              ut.full_name as transporter_name
       FROM reviews r
       JOIN users uc ON r.client_id = uc.id
       JOIN users ut ON r.transporter_id = ut.id
       WHERE r.transporter_id = $1 ORDER BY r.created_at DESC`,
      [req.params.transporterId]
    );
    res.json({ reviews: result.rows.map(formatReview) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// POST /api/reviews
router.post('/', auth, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { orderId, orderNumber, transporterId, transporterName, rating, comment, punctuality, communication, packageCondition, reliability } = req.body;

    const orderResult = await client.query('SELECT * FROM transport_orders WHERE id=$1', [orderId]);
    if (orderResult.rows.length === 0) return res.status(404).json({ message: 'Commande introuvable' });
    const order = orderResult.rows[0];
    if (!order.review_authorized || order.status !== 'COMPLETED' || order.client_id !== req.userId) {
      return res.status(403).json({ message: 'Non autorisé à laisser un avis' });
    }

    const existing = await client.query('SELECT id FROM reviews WHERE order_id=$1 AND client_id=$2', [orderId, req.userId]);
    if (existing.rows.length > 0) return res.status(400).json({ message: 'Avis déjà soumis' });

    const id = uuidv4();
    await client.query(
      `INSERT INTO reviews (id, order_id, order_number, transporter_id, client_id, rating, comment, punctuality, communication, package_condition, reliability)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`,
      [id, orderId, orderNumber, transporterId, req.userId, rating, comment || '', punctuality || 0, communication || 0, packageCondition || 0, reliability || 0]
    );

    // Mettre à jour la note moyenne du transporteur
    await client.query(
      `UPDATE users SET
         average_rating = (SELECT AVG(rating) FROM reviews WHERE transporter_id=$1),
         total_reviews  = (SELECT COUNT(*) FROM reviews WHERE transporter_id=$1),
         updated_at = NOW()
       WHERE id=$1`,
      [transporterId]
    );

    await client.query('COMMIT');
    res.status(201).json({ message: 'Avis soumis avec succès' });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  } finally {
    client.release();
  }
});

module.exports = router;
