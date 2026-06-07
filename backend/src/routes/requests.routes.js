const express = require('express');
const { v4: uuidv4 } = require('uuid');
const pool = require('../db');
const auth = require('../middleware/auth');

const router = express.Router();

const REQ_SELECT = `
  SELECT r.*,
    uc.full_name as client_name, uc.photo_url as client_photo_url,
    ut.full_name as transporter_name
  FROM transport_requests r
  JOIN users uc ON r.client_id = uc.id
  JOIN users ut ON r.transporter_id = ut.id
`;

function formatRequest(row) {
  return {
    id: row.id,
    adId: row.ad_id,
    transporterId: row.transporter_id,
    transporterName: row.transporter_name,
    clientId: row.client_id,
    clientName: row.client_name,
    clientPhotoUrl: row.client_photo_url || null,
    message: row.message || null,
    status: row.status,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

// GET /api/requests/as-client
router.get('/as-client', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `${REQ_SELECT} WHERE r.client_id = $1 ORDER BY r.created_at DESC`,
      [req.userId]
    );
    res.json({ requests: result.rows.map(formatRequest) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/requests/incoming — demandes en attente pour moi en tant que transporteur
router.get('/incoming', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `${REQ_SELECT} WHERE r.transporter_id = $1 AND r.status = 'PENDING' ORDER BY r.created_at DESC`,
      [req.userId]
    );
    res.json({ requests: result.rows.map(formatRequest) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// POST /api/requests — envoyer une demande
router.post('/', auth, async (req, res) => {
  try {
    const { adId, transporterId, transporterName, message } = req.body;
    const clientResult = await pool.query('SELECT * FROM users WHERE id = $1', [req.userId]);
    const client = clientResult.rows[0];
    if (!client) return res.status(404).json({ message: 'Utilisateur introuvable' });

    const id = uuidv4();
    await pool.query(
      `INSERT INTO transport_requests (id, ad_id, transporter_id, client_id, message, status)
       VALUES ($1,$2,$3,$4,$5,'PENDING')`,
      [id, adId, transporterId, req.userId, message || null]
    );
    const result = await pool.query(`${REQ_SELECT} WHERE r.id = $1`, [id]);
    res.status(201).json({ request: formatRequest(result.rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/requests/:id/accept
router.patch('/:id/accept', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE transport_requests SET status='ACCEPTED', updated_at=NOW()
       WHERE id=$1 AND transporter_id=$2 RETURNING id`,
      [req.params.id, req.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'Demande introuvable' });
    const updated = await pool.query(`${REQ_SELECT} WHERE r.id = $1`, [req.params.id]);
    res.json({ request: formatRequest(updated.rows[0]) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/requests/:id/reject
router.patch('/:id/reject', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `UPDATE transport_requests SET status='REJECTED', updated_at=NOW()
       WHERE id=$1 AND transporter_id=$2 RETURNING id`,
      [req.params.id, req.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'Demande introuvable' });
    const updated = await pool.query(`${REQ_SELECT} WHERE r.id = $1`, [req.params.id]);
    res.json({ request: formatRequest(updated.rows[0]) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;
