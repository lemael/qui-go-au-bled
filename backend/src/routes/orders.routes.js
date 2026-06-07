const express = require('express');
const { v4: uuidv4 } = require('uuid');
const pool = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

const ORDER_SELECT = `
  SELECT o.*,
    ut.full_name as transporter_name, ut.photo_url as transporter_photo_url,
    uc.full_name as client_name, uc.photo_url as client_photo_url,
    c.author_id as c_author_id, ua.full_name as c_author_name,
    c.reason as c_reason, c.cancelled_at as c_cancelled_at
  FROM transport_orders o
  JOIN users ut ON o.transporter_id = ut.id
  JOIN users uc ON o.client_id = uc.id
  LEFT JOIN cancellations c ON c.order_id = o.id
  LEFT JOIN users ua ON c.author_id = ua.id
`;

function formatOrder(row) {
  return {
    id: row.id,
    orderNumber: row.order_number,
    adId: row.ad_id,
    requestId: row.request_id,
    transporterId: row.transporter_id,
    transporterName: row.transporter_name,
    transporterPhotoUrl: row.transporter_photo_url || null,
    clientId: row.client_id,
    clientName: row.client_name,
    clientPhotoUrl: row.client_photo_url || null,
    departureCity: row.departure_city,
    arrivalCity: row.arrival_city,
    flightDate: row.flight_date instanceof Date ? row.flight_date.toISOString() : String(row.flight_date),
    pricePerKg: parseFloat(row.price_per_kg),
    status: row.status,
    reviewAuthorized: row.review_authorized || false,
    cancellationInfo: row.c_author_id ? {
      authorId: row.c_author_id,
      authorName: row.c_author_name,
      reason: row.c_reason,
      cancelledAt: row.c_cancelled_at instanceof Date ? row.c_cancelled_at.toISOString() : String(row.c_cancelled_at),
    } : null,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

// GET /api/orders — mes commandes (client ou transporteur)
router.get('/', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `${ORDER_SELECT} WHERE o.transporter_id = $1 OR o.client_id = $1 ORDER BY o.created_at DESC`,
      [req.userId]
    );
    res.json({ orders: result.rows.map(formatOrder) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/orders/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const result = await pool.query(`${ORDER_SELECT} WHERE o.id = $1`, [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ message: 'Commande introuvable' });
    res.json({ order: formatOrder(result.rows[0]) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// POST /api/orders — créer une commande (après acceptation d'une demande)
router.post('/', auth, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Générer le numéro de commande
    const counterResult = await client.query(
      `UPDATE counters SET value = value + 1 WHERE name = 'transport_orders' RETURNING value`
    );
    const count = counterResult.rows[0].value;
    const year = new Date().getFullYear();
    const orderNumber = `TRP-${year}-${String(count).padStart(6, '0')}`;

    const { adId, requestId, transporterId, clientId, departureCity, arrivalCity, flightDate, pricePerKg } = req.body;
    const id = uuidv4();
    await client.query(
      `INSERT INTO transport_orders (id, order_number, ad_id, request_id, transporter_id, client_id,
       departure_city, arrival_city, flight_date, price_per_kg, status, review_authorized)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'ACCEPTED',false)`,
      [id, orderNumber, adId, requestId, transporterId, clientId, departureCity, arrivalCity, flightDate, pricePerKg]
    );

    await client.query('COMMIT');
    const result = await pool.query(`${ORDER_SELECT} WHERE o.id = $1`, [id]);
    res.status(201).json({ order: formatOrder(result.rows[0]), orderNumber });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  } finally {
    client.release();
  }
});

// PATCH /api/orders/:id/start
router.patch('/:id/start', auth, async (req, res) => {
  try {
    await pool.query(
      `UPDATE transport_orders SET status='IN_PROGRESS', updated_at=NOW() WHERE id=$1 AND transporter_id=$2`,
      [req.params.id, req.userId]
    );
    res.json({ message: 'Service démarré' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/orders/:id/complete
router.patch('/:id/complete', auth, async (req, res) => {
  try {
    await pool.query(
      `UPDATE transport_orders SET status='COMPLETED', review_authorized=true, updated_at=NOW() WHERE id=$1 AND transporter_id=$2`,
      [req.params.id, req.userId]
    );
    res.json({ message: 'Service terminé' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// POST /api/orders/:id/cancel
router.post('/:id/cancel', auth, async (req, res) => {
  const dbClient = await pool.connect();
  try {
    await dbClient.query('BEGIN');
    const { reason } = req.body;
    await dbClient.query(
      `UPDATE transport_orders SET status='CANCELLED', updated_at=NOW() WHERE id=$1`,
      [req.params.id]
    );
    await dbClient.query(
      `INSERT INTO cancellations (id, order_id, author_id, reason) VALUES ($1,$2,$3,$4)`,
      [uuidv4(), req.params.id, req.userId, reason || '']
    );
    await dbClient.query('COMMIT');
    res.json({ message: 'Commande annulée' });
  } catch (err) {
    await dbClient.query('ROLLBACK');
    res.status(500).json({ message: 'Erreur serveur' });
  } finally {
    dbClient.release();
  }
});

module.exports = router;
