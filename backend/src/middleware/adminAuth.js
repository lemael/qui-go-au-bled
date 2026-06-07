const jwt = require('jsonwebtoken');
const pool = require('../db');

module.exports = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Non autorisé' });
  }
  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    req.userEmail = decoded.email;
    // Vérifier le rôle admin en DB
    const result = await pool.query('SELECT role FROM users WHERE id = $1', [decoded.userId]);
    if (result.rows.length === 0 || result.rows[0].role !== 'admin') {
      return res.status(403).json({ message: 'Accès refusé : rôle admin requis' });
    }
    next();
  } catch {
    return res.status(401).json({ message: 'Token invalide ou expiré' });
  }
};
