import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { getDb, addAuditLog } from '../db';

const JWT_SECRET = process.env.NEXUS_JWT_SECRET || 'default-secret-change-in-production';
const JWT_EXPIRES_IN = process.env.NEXUS_JWT_EXPIRES_IN || '24h';

interface LoginRequest {
  username: string;
  password: string;
}

interface AuthToken {
  id: number;
  username: string;
  is_super_admin: boolean;
  iat: number;
  exp: number;
}

/**
 * Hache un mot de passe avec bcrypt
 */
export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

/**
 * Compare un mot de passe avec son hash
 */
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

/**
 * Authentifie un administrateur
 */
export async function authenticateAdmin(req: any, res: any) {
  const { username, password } = req.body as LoginRequest;
  const ip = req.ip || req.connection.remoteAddress;

  // Validation basique
  if (!username || !password) {
    return res.status(400).json({ 
      error: 'Username and password are required' 
    });
  }

  if (typeof username !== 'string' || typeof password !== 'string') {
    return res.status(400).json({ 
      error: 'Invalid input types' 
    });
  }

  if (username.length < 3 || password.length < 6) {
    return res.status(400).json({ 
      error: 'Invalid credentials' 
    });
  }

  try {
    const db = getDb();
    const admin = db.prepare(`
      SELECT id, username, password_hash, is_super_admin 
      FROM admins 
      WHERE username = ? AND status = 'active'
    `).get(username) as any;

    if (!admin) {
      // Attendre un peu pour éviter le timing attack
      await new Promise(resolve => setTimeout(resolve, 500));
      addAuditLog(null, 'LOGIN_FAILED', 'admin', username, 'Invalid credentials', ip);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Vérifier le mot de passe
    const passwordValid = await verifyPassword(password, admin.password_hash);
    if (!passwordValid) {
      await new Promise(resolve => setTimeout(resolve, 500));
      addAuditLog(admin.id, 'LOGIN_FAILED', 'admin', username, 'Wrong password', ip);
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Générer le JWT
    const token = jwt.sign(
      {
        id: admin.id,
        username: admin.username,
        is_super_admin: admin.is_super_admin
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    // Mettre à jour last_login
    db.prepare('UPDATE admins SET last_login = CURRENT_TIMESTAMP WHERE id = ?').run(admin.id);

    // Logger la connexion réussie
    addAuditLog(admin.id, 'LOGIN_SUCCESS', 'admin', username, 'Successful login', ip);

    res.json({
      token,
      admin: {
        id: admin.id,
        username: admin.username,
        is_super_admin: admin.is_super_admin
      }
    });
  } catch (e: any) {
    console.error(`[AUTH ERROR] ${e.message}`);
    res.status(500).json({ error: 'Authentication failed' });
  }
}

/**
 * Middleware pour vérifier le JWT
 */
export function verifyToken(req: any, res: any, next: any) {
  const authHeader = req.headers['authorization'];
  const token = authHeader?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as AuthToken;
    req.user = decoded;
    next();
  } catch (e: any) {
    if (e.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}

/**
 * Middleware pour vérifier les droits super admin
 */
export function requireSuperAdmin(req: any, res: any, next: any) {
  if (!req.user?.is_super_admin) {
    return res.status(403).json({ error: 'Super admin access required' });
  }
  next();
}

/**
 * Crée un nouvel administrateur
 */
export async function createAdmin(req: any, res: any) {
  const { username, password } = req.body;
  const ip = req.ip || req.connection.remoteAddress;

  // Validation
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }

  if (username.length < 3 || password.length < 6) {
    return res.status(400).json({ 
      error: 'Username must be at least 3 chars, password at least 6 chars' 
    });
  }

  if (!/^[a-zA-Z0-9_-]+$/.test(username)) {
    return res.status(400).json({ 
      error: 'Username can only contain letters, numbers, dashes, and underscores' 
    });
  }

  try {
    const db = getDb();

    // Vérifier si l'admin existe déjà
    const existing = db.prepare('SELECT id FROM admins WHERE username = ?').get(username);
    if (existing) {
      return res.status(400).json({ error: 'Username already exists' });
    }

    // Hash le mot de passe
    const password_hash = await hashPassword(password);

    // Créer l'admin
    const stmt = db.prepare(`
      INSERT INTO admins (id, username, password_hash, status)
      VALUES (?, ?, ?, 'active')
    `);
    stmt.run(Date.now().toString(), username, password_hash);

    // Logger
    addAuditLog(req.user?.id, 'CREATE_ADMIN', 'admin', username, `Created admin: ${username}`, ip);

    res.status(201).json({
      message: 'Admin created successfully',
      username
    });
  } catch (e: any) {
    console.error(`[CREATE ADMIN ERROR] ${e.message}`);
    res.status(500).json({ error: 'Failed to create admin' });
  }
}

/**
 * Change le mot de passe d'un administrateur
 */
export async function changePassword(req: any, res: any) {
  const { old_password, new_password } = req.body;
  const admin_id = req.user?.id;
  const ip = req.ip || req.connection.remoteAddress;

  if (!old_password || !new_password) {
    return res.status(400).json({ error: 'Both passwords required' });
  }

  if (new_password.length < 6) {
    return res.status(400).json({ error: 'New password must be at least 6 characters' });
  }

  try {
    const db = getDb();
    const admin = db.prepare('SELECT password_hash FROM admins WHERE id = ?').get(admin_id) as any;

    if (!admin) {
      return res.status(404).json({ error: 'Admin not found' });
    }

    // Vérifier l'ancien mot de passe
    const passwordValid = await verifyPassword(old_password, admin.password_hash);
    if (!passwordValid) {
      addAuditLog(admin_id, 'CHANGE_PASSWORD_FAILED', 'admin', admin_id, 'Wrong password', ip);
      return res.status(401).json({ error: 'Invalid password' });
    }

    // Hash le nouveau mot de passe
    const new_password_hash = await hashPassword(new_password);

    // Mettre à jour
    db.prepare('UPDATE admins SET password_hash = ? WHERE id = ?').run(new_password_hash, admin_id);

    // Logger
    addAuditLog(admin_id, 'CHANGE_PASSWORD', 'admin', admin_id, 'Password changed', ip);

    res.json({ message: 'Password changed successfully' });
  } catch (e: any) {
    console.error(`[CHANGE PASSWORD ERROR] ${e.message}`);
    res.status(500).json({ error: 'Failed to change password' });
  }
}
