const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

const JWT_SECRET = process.env.JWT_SECRET || 'ai_healthcare_secret_key_2026';
const JWT_EXPIRY = '7d';

class AuthService {
  generateToken(user) {
    return jwt.sign(
      { id: user.id, email: user.email, role: user.role, name: user.name },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRY }
    );
  }

  verifyToken(token) {
    try {
      return jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return null;
    }
  }

  async hashPassword(password) {
    return bcrypt.hash(password, 10);
  }

  async comparePassword(password, hash) {
    return bcrypt.compare(password, hash);
  }

  // Express middleware
  authMiddleware(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }
    const token = authHeader.split(' ')[1];
    const decoded = this.verifyToken(token);
    if (!decoded) return res.status(401).json({ error: 'Invalid or expired token' });
    req.user = decoded;
    next();
  }

  // Role check middleware
  roleMiddleware(...roles) {
    return (req, res, next) => {
      if (!req.user || !roles.includes(req.user.role)) {
        return res.status(403).json({ error: 'Access denied' });
      }
      next();
    };
  }
}

module.exports = new AuthService();
