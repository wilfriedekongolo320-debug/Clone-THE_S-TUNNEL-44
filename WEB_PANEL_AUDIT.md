# 🖥️ RAPPORT D'AUDIT - PANEL WEB NEXUS TUNNEL

## 📋 Résumé Exécutif

Le panel web Nexus Tunnel présente **6 problèmes critiques** et **8 problèmes modérés** qui empêchent un déploiement fiable. Ce rapport détaille chaque problème et propose des corrections.

---

## 🔴 PROBLÈMES CRITIQUES

### **1. Configuration Manquante du Fichier config.json** ❌

**Fichier:** `nexus-web/install.sh` (ligne 166-175)

**Problème:**
```bash
cat > "$CONFIG_FILE" <<JSON
{
  "port": $port,
  "admin_user": "$admin_user",
  "admin_password": "$admin_pass",
  "jwt_secret": "$jwt_secret",
  "scripts_dir": "/usr/local/sbin",
  "db_dir": "$CONFIG_DIR"
}
JSON
```

**Problèmes identifiés:**
- ❌ Pas d'authentification SSH configurée
- ❌ Pas de limite de ressources
- ❌ Pas de configuration TLS/HTTPS
- ❌ Pas d'adresse d'écoute (localhost par défaut - inaccessible à distance)

**Solution:**
```bash
cat > "$CONFIG_FILE" <<JSON
{
  "port": $port,
  "host": "0.0.0.0",
  "admin_user": "$admin_user",
  "admin_password": "$admin_pass",
  "jwt_secret": "$jwt_secret",
  "jwt_expires_in": "24h",
  "scripts_dir": "/usr/local/sbin",
  "db_dir": "$CONFIG_DIR",
  "cors_origin": "*",
  "rate_limit": {
    "window_ms": 900000,
    "max_requests": 100
  },
  "session_timeout": 86400,
  "max_connections": 100,
  "log_level": "info",
  "enable_https": false,
  "ssl_cert": "",
  "ssl_key": ""
}
JSON
```

---

### **2. Chemin d'accès au Fichier Config Incohérent** ❌

**Fichier:** `nexus-web/server/index.ts` (ligne 17)

**Problème:**
```typescript
const CONFIG_FILE = process.env.NEXUS_CONFIG || '/etc/nexus-tunnel-web/config.json';
```

**Problèmes:**
- ❌ Variable d'environnement non définie dans systemd
- ❌ Chemin par défaut différent du PATH_CONFIG créé
- ❌ Aucune validation du fichier config

**Solution:**
```typescript
import path from 'path';

const CONFIG_FILE = process.env.NEXUS_CONFIG || path.join(
  process.env.NEXUS_DB_DIR || '/etc/nexus-tunnel-web',
  'config.json'
);

// Validation du fichier config
if (!fs.existsSync(CONFIG_FILE)) {
  console.error(`[ERROR] Configuration file not found: ${CONFIG_FILE}`);
  process.exit(1);
}

let config: any = {};
try {
  config = JSON.parse(fs.readFileSync(CONFIG_FILE, 'utf8'));
  console.log(`[OK] Configuration loaded from ${CONFIG_FILE}`);
} catch (e: any) {
  console.error(`[ERROR] Failed to parse config: ${e.message}`);
  process.exit(1);
}
```

---

### **3. Database Initialization Manquante** ❌

**Fichier:** `nexus-web/server/db.ts`

**Problème:**
- ❌ Pas de migration automatique de la DB
- ❌ Pas de vérification de l'initialisation
- ❌ La fonction `seedSuperAdmin` n'existe pas/n'est pas appelée

**Solution:**
Créer `nexus-web/server/db.ts`:
```typescript
import sqlite3 from 'better-sqlite3';
import path from 'path';
import fs from 'fs';

const DB_DIR = process.env.NEXUS_DB_DIR || '/etc/nexus-tunnel-web';
const DB_FILE = path.join(DB_DIR, 'nexus.db');

let db: any;

export function getDb() {
  if (!db) {
    // Créer le répertoire s'il n'existe pas
    if (!fs.existsSync(DB_DIR)) {
      fs.mkdirSync(DB_DIR, { recursive: true, mode: 0o700 });
    }

    db = new sqlite3(DB_FILE);
    db.pragma('journal_mode = WAL');
    
    // Initialiser la DB
    initializeDatabase();
  }
  return db;
}

export function initializeDatabase() {
  try {
    // Table Admins
    db.exec(`
      CREATE TABLE IF NOT EXISTS admins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        is_super_admin BOOLEAN DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Table Resellers
    db.exec(`
      CREATE TABLE IF NOT EXISTS resellers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        admin_id INTEGER NOT NULL,
        balance REAL DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(admin_id) REFERENCES admins(id)
      )
    `);

    // Table Clients
    db.exec(`
      CREATE TABLE IF NOT EXISTS clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        protocol TEXT NOT NULL,
        reseller_id INTEGER NOT NULL,
        expires_at DATETIME,
        status TEXT DEFAULT 'active',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(reseller_id) REFERENCES resellers(id)
      )
    `);

    // Table Logs
    db.exec(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        admin_id INTEGER,
        action TEXT NOT NULL,
        target_type TEXT,
        target_id TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(admin_id) REFERENCES admins(id)
      )
    `);

    console.log('[OK] Database initialized successfully');
  } catch (e: any) {
    console.error(`[ERROR] Database initialization failed: ${e.message}`);
    throw e;
  }
}

export function seedSuperAdmin(username: string, password_hash: string) {
  try {
    const db = getDb();
    const stmt = db.prepare(`
      INSERT OR IGNORE INTO admins (username, password_hash, is_super_admin)
      VALUES (?, ?, 1)
    `);
    stmt.run(username, password_hash);
    console.log('[OK] Super admin seeded');
  } catch (e: any) {
    console.error(`[ERROR] Failed to seed super admin: ${e.message}`);
  }
}
```

---

### **4. CORS Configuration Insuffisante** ❌

**Fichier:** `nexus-web/server/index.ts` (ligne ~40)

**Problème:**
```typescript
app.use(cors());  // CORS trop permissif
```

**Solution:**
```typescript
const corsOptions = {
  origin: (origin: string | undefined, callback: any) => {
    // Récupérer les origines autorisées depuis la config
    const allowedOrigins = config.cors_origin === '*' 
      ? ['*'] 
      : (config.cors_origin || '').split(',').map(o => o.trim());
    
    if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'), false);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 3600
};

app.use(cors(corsOptions));
```

---

### **5. Authentification JWT Non Validée** ❌

**Fichier:** `nexus-web/server/routes/auth.ts`

**Problème:**
- ❌ Pas de validation du mot de passe (plaintext)
- ❌ Pas de hash bcrypt
- ❌ Pas de refresh token

**Solution:**
```typescript
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

export async function loginAdmin(req: any, res: any) {
  const { username, password } = req.body;
  
  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }

  try {
    const db = getDb();
    const admin = db.prepare('SELECT * FROM admins WHERE username = ?').get(username);
    
    if (!admin) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Vérifier le mot de passe
    const passwordValid = await bcrypt.compare(password, admin.password_hash);
    if (!passwordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Générer JWT
    const token = jwt.sign(
      { 
        id: admin.id, 
        username: admin.username,
        is_super_admin: admin.is_super_admin 
      },
      config.jwt_secret || 'default-secret',
      { expiresIn: config.jwt_expires_in || '24h' }
    );

    res.json({ token, admin: { username: admin.username, is_super_admin: admin.is_super_admin } });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
}
```

---

### **6. Health Check Endpoint Manquant** ❌

**Fichier:** `nexus-web/server/index.ts`

**Problème:**
- ❌ Pas de endpoint `/api/health`
- ❌ Le watchdog cron ne peut pas vérifier le statut
- ❌ Pas de logs de santé

**Solution:**
```typescript
// Ajouter le health check route
app.get('/api/health', (req: any, res: any) => {
  try {
    const db = getDb();
    const result = db.prepare('SELECT 1').get();
    res.json({ 
      status: 'ok',
      timestamp: new Date().toISOString(),
      database: 'connected',
      uptime: process.uptime()
    });
  } catch (e: any) {
    res.status(503).json({ 
      status: 'error',
      error: e.message 
    });
  }
});
```

---

## 🟠 PROBLÈMES MODÉRÉS

### **7. Compilation TypeScript Avec Avertissements** ⚠️

**Fichier:** `nexus-web/install.sh` (ligne 152)

```bash
if ! npm run build 2>&1; then
  log_warn "Avertissements pendant la compilation TypeScript..."
```

**Problème:**
- ⚠️ Les avertissements TypeScript sont ignorés
- ⚠️ Risque de bugs en production

**Solution:**
```bash
log_info "Compilation du serveur TypeScript (strict mode)..."
npm run build -- --noEmitOnError 2>&1
if [ $? -ne 0 ]; then
  log_error "Échec de la compilation TypeScript. Correction nécessaire."
  exit 1
fi
```

---

### **8. Variables d'Environnement Mal Configurées** ⚠️

**Fichier:** `nexus-web/install.sh` (ligne 196-201)

```bash
Environment=NEXUS_CONFIG=$CONFIG_FILE
Environment=NEXUS_DB_DIR=$CONFIG_DIR
Environment=NEXUS_JWT_SECRET=$jwt_secret
Environment=NEXUS_ADMIN_USER=$admin_user
Environment=NEXUS_ADMIN_PASS=$admin_pass
```

**Problème:**
- ⚠️ Mot de passe en plaintext dans le service systemd
- ⚠️ Lisible par n'importe quel utilisateur avec `systemctl cat`

**Solution:**
```bash
cat > "$SERVICE_FILE" <<SVC
[Unit]
Description=Nexus Tunnel Web Panel
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$NEXUS_WEB_DIR
ExecStart=/usr/bin/node $NEXUS_WEB_DIR/dist/server/index.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production
Environment=NEXUS_CONFIG=$CONFIG_FILE
Environment=NEXUS_DB_DIR=$CONFIG_DIR
StandardOutput=journal
StandardError=journal
ProtectSystem=strict
ProtectHome=yes
NoNewPrivileges=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
SVC
```

---

### **9. Gestion des Ports Insuffisante** ⚠️

**Fichier:** `nexus-web/install.sh` (ligne 42-52)

```bash
find_available_port() {
  local candidates=(2087 2096 8787 3001 9090 8088 9180)
  for port in "${candidates[@]}"; do
    if ! ss -tlnp 2>/dev/null | grep -q ":$port " && \
       ! netstat -tlnp 2>/dev/null | grep -q ":$port "; then
      echo "$port"
      return 0
    fi
  done
  echo "2087"  # Fallback port
}
```

**Problème:**
- ⚠️ Fallback à port 2087 peut créer un conflit
- ⚠️ Pas de vérification de droits (ports < 1024)

**Solution:**
```bash
find_available_port() {
  local candidates=(2087 2096 8787 3001 9090 8088 9180)
  for port in "${candidates[@]}"; do
    if ! ss -tlnp 2>/dev/null | grep -q ":$port " && \
       ! netstat -tlnp 2>/dev/null | grep -q ":$port "; then
      echo "$port"
      return 0
    fi
  done
  
  # Si tous les ports sont occupés, chercher un port libre automatiquement
  local port=$(shuf -i 10000-65000 -n 1)
  while ss -tlnp 2>/dev/null | grep -q ":$port "; do
    port=$(shuf -i 10000-65000 -n 1)
  done
  echo "$port"
}
```

---

### **10. Logging Insuffisant** ⚠️

**Fichier:** `nexus-web/server/index.ts`

**Problème:**
- ⚠️ Pas de logs structurés
- ⚠️ Pas de rotation des logs
- ⚠️ Erreurs perdues

**Solution:**
```typescript
import pino from 'pino';

const logger = pino({
  level: config.log_level || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: false,
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname'
    }
  }
});

app.use((req: any, res: any, next: any) => {
  logger.info({
    method: req.method,
    path: req.path,
    ip: req.ip
  });
  next();
});

export default logger;
```

---

### **11. Pas de Rate Limiting sur les APIs** ⚠️

**Fichier:** `nexus-web/server/index.ts`

**Problème:**
- ⚠️ Possible brute-force sur /api/auth/login
- ⚠️ Pas de protection contre les attaques DDoS

**Solution:**
```typescript
import rateLimit from 'express-rate-limit';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 tentatives par IP
  message: 'Trop de tentatives de connexion, réessayez plus tard',
  standardHeaders: true,
  legacyHeaders: false
});

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});

app.post('/api/auth/login', loginLimiter, authRouter);
app.use('/api/', apiLimiter);
```

---

### **12. Pas de Validation des Entrées** ⚠️

**Fichier:** `nexus-web/server/routes/`

**Problème:**
- ⚠️ SQL injection possible
- ⚠️ Pas de sanitization

**Solution:**
```typescript
import joi from 'joi';

const createClientSchema = joi.object({
  username: joi.string().alphanum().min(3).max(30).required(),
  protocol: joi.string().valid('ssh', 'vmess', 'vless', 'trojan').required(),
  days: joi.number().integer().min(1).max(365).required()
});

export function validateClientCreation(req: any, res: any, next: any) {
  const { error, value } = createClientSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ error: error.details[0].message });
  }
  req.validated = value;
  next();
}
```

---

### **13. Pas d'API Documentation** ⚠️

**Problème:**
- ⚠️ Pas de Swagger/OpenAPI
- ⚠️ Les clients ne savent pas comment utiliser l'API

**Solution:**
Ajouter Swagger:
```typescript
import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Nexus Tunnel Web API',
      version: '1.0.0',
    },
    servers: [{ url: `http://localhost:${config.port}` }],
  },
  apis: ['./server/routes/*.ts'],
};

const specs = swaggerJsdoc(options);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
```

---

### **14. Aucun Test Automatisé** ⚠️

**Problème:**
- ⚠️ Pas de tests unitaires
- ⚠️ Risque de régression

**Solution:**
Ajouter Jest:
```bash
npm install -D jest @types/jest ts-jest
```

Créer `jest.config.js`:
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  collectCoverageFrom: ['server/**/*.ts'],
  coverageThreshold: { global: { branches: 70, functions: 70 } }
};
```

---

## ✅ CHECKLIST DE CORRECTIONS

### Phase 1: Critique (Bloquer le déploiement)
- [ ] Ajouter configuration complète du config.json
- [ ] Fixer le chemin config avec validation
- [ ] Implémenter database.ts avec migration
- [ ] Sécuriser CORS
- [ ] Implémenter JWT avec bcrypt
- [ ] Ajouter health check endpoint

### Phase 2: Important (Avant production)
- [ ] Activer strict mode TypeScript
- [ ] Retirer les secrets des variables env
- [ ] Améliorer la gestion des ports
- [ ] Ajouter logging structuré
- [ ] Implémenter rate limiting
- [ ] Ajouter validation des entrées

### Phase 3: Nice-to-have (Amélioration)
- [ ] Documentation Swagger
- [ ] Tests automatisés
- [ ] Monitoring/Alerting
- [ ] Backup de la DB

---

## 📊 Tableau Récapitulatif

| # | Problème | Sévérité | Fichier | Correction |
|---|----------|----------|---------|-----------|
| 1 | Config.json incomplet | CRITIQUE | install.sh | Ajouter tous les champs requis |
| 2 | Chemin config incohérent | CRITIQUE | server/index.ts | Ajouter validation |
| 3 | DB non initialisée | CRITIQUE | db.ts | Créer le fichier |
| 4 | CORS trop permissif | CRITIQUE | server/index.ts | Sécuriser |
| 5 | JWT pas validé | CRITIQUE | auth.ts | Ajouter bcrypt |
| 6 | Health check absent | CRITIQUE | server/index.ts | Ajouter endpoint |
| 7 | Build warnings ignorés | MODÉRÉ | install.sh | Strict mode |
| 8 | Secrets en plaintext | MODÉRÉ | install.sh | Fichier config uniquement |
| 9 | Port fallback faible | MODÉRÉ | install.sh | Chercher port libre |
| 10 | Logging insuffisant | MODÉRÉ | server/index.ts | Ajouter pino |
| 11 | Pas de rate limiting | MODÉRÉ | server/index.ts | Ajouter express-ratelimit |
| 12 | Pas de validation | MODÉRÉ | routes/*.ts | Ajouter joi |
| 13 | Pas de docs API | MODÉRÉ | server/index.ts | Ajouter Swagger |
| 14 | Pas de tests | MODÉRÉ | tests/ | Ajouter Jest |

---

## 🚀 Recommandations Prioritaires

**Immédiat (Bloquer):**
1. ✅ Fixer la configuration (critique pour le démarrage)
2. ✅ Initialiser la DB (crash sinon)
3. ✅ Ajouter health check (watchdog ne fonctionne pas)

**Court terme (1-2 jours):**
4. ✅ Sécuriser l'authentification
5. ✅ Valider les entrées utilisateur
6. ✅ Ajouter rate limiting

**Moyen terme (1-2 semaines):**
7. ✅ Ajouter documentation API
8. ✅ Implémenter tests
9. ✅ Monitoring/Alerting

---

**Status:** 🔴 Non Prêt pour Production  
**Correctifs Nécessaires:** 14  
**Estimé:** 8-12 heures de développement
