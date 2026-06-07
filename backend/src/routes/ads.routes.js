const express = require('express');
const { v4: uuidv4 } = require('uuid');
const pool = require('../db');
const auth = require('../middleware/auth');

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

// GET /api/ads  — annonces actives avec filtres optionnels
router.get('/', auth, async (req, res) => {
  try {
    const { departureCity, arrivalCity, flightDate, limit = 20, offset = 0 } = req.query;
    let query = `${AD_SELECT} WHERE a.status = 'active'`;
    const values = [];
    let i = 1;
    if (departureCity) { query += ` AND LOWER(a.departure_city) = $${i++}`; values.push(departureCity.toLowerCase()); }
    if (arrivalCity)   { query += ` AND LOWER(a.arrival_city) = $${i++}`;   values.push(arrivalCity.toLowerCase()); }
    if (flightDate)    { query += ` AND a.flight_date = $${i++}`;            values.push(flightDate); }
    query += ` ORDER BY a.flight_date ASC LIMIT $${i++} OFFSET $${i++}`;
    values.push(parseInt(limit), parseInt(offset));
    const result = await pool.query(query, values);
    res.json({ ads: result.rows.map(formatAd) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/ads/my — mes annonces
router.get('/my', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `${AD_SELECT} WHERE a.transporter_id = $1 ORDER BY a.created_at DESC`,
      [req.userId]
    );
    res.json({ ads: result.rows.map(formatAd) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/ads/my/active — mon annonce active
router.get('/my/active', auth, async (req, res) => {
  try {
    const result = await pool.query(
      `${AD_SELECT} WHERE a.transporter_id = $1 AND a.status = 'active' LIMIT 1`,
      [req.userId]
    );
    res.json({ ad: result.rows.length > 0 ? formatAd(result.rows[0]) : null });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// GET /api/ads/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const result = await pool.query(`${AD_SELECT} WHERE a.id = $1`, [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ message: 'Annonce introuvable' });
    res.json({ ad: formatAd(result.rows[0]) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// POST /api/ads
router.post('/', auth, async (req, res) => {
  try {
    const { departureCity, arrivalCity, flightDate, flightTime, maxWeightKg, pricePerKg, description } = req.body;
    const id = uuidv4();
    await pool.query(
      `INSERT INTO transport_ads (id, transporter_id, departure_city, arrival_city, flight_date, flight_time, max_weight_kg, price_per_kg, description, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'pending')`,
      [id, req.userId, departureCity, arrivalCity, flightDate, flightTime || '', maxWeightKg, pricePerKg, description || '']
    );
    const result = await pool.query(`${AD_SELECT} WHERE a.id = $1`, [id]);
    res.status(201).json({ ad: formatAd(result.rows[0]) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PUT /api/ads/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const { departureCity, arrivalCity, flightDate, flightTime, maxWeightKg, pricePerKg, description, status } = req.body;
    const result = await pool.query(
      `UPDATE transport_ads SET departure_city=$1, arrival_city=$2, flight_date=$3, flight_time=$4,
       max_weight_kg=$5, price_per_kg=$6, description=$7, status=COALESCE($8, status), updated_at=NOW()
       WHERE id=$9 AND transporter_id=$10 RETURNING id`,
      [departureCity, arrivalCity, flightDate, flightTime, maxWeightKg, pricePerKg, description, status, req.params.id, req.userId]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: 'Annonce introuvable' });
    const updated = await pool.query(`${AD_SELECT} WHERE a.id = $1`, [req.params.id]);
    res.json({ ad: formatAd(updated.rows[0]) });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// DELETE /api/ads/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    await pool.query('DELETE FROM transport_ads WHERE id=$1 AND transporter_id=$2', [req.params.id, req.userId]);
    res.json({ message: 'Annonce supprimée' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// PATCH /api/ads/:id/deactivate
router.patch('/:id/deactivate', auth, async (req, res) => {
  try {
    await pool.query(
      `UPDATE transport_ads SET status='inactive', updated_at=NOW() WHERE id=$1 AND transporter_id=$2`,
      [req.params.id, req.userId]
    );
    res.json({ message: 'Annonce désactivée' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;
module.exports.formatAd = formatAd;
