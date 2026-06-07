-- ============================================================
-- QUI GO AU BLED - Schéma PostgreSQL (Railway)
-- Utilisé pour les analytics, rapports et données historiques
-- ============================================================

-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid    VARCHAR(128) UNIQUE NOT NULL,
    full_name       VARCHAR(255) NOT NULL,
    email           VARCHAR(320) UNIQUE NOT NULL,
    phone           VARCHAR(20),
    address         TEXT,
    photo_url       TEXT,
    role            VARCHAR(20) NOT NULL CHECK (role IN ('transporter', 'client')),
    average_rating  DECIMAL(3,2) DEFAULT 0.00,
    total_reviews   INTEGER DEFAULT 0,
    fcm_token       TEXT,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ─────────────────────────────────────────────────────────────
-- TRANSPORT ADS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE transport_ads (
    id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firestore_id             VARCHAR(128) UNIQUE,
    transporter_id           UUID NOT NULL REFERENCES users(id),
    departure_city           VARCHAR(255) NOT NULL,
    arrival_city             VARCHAR(255) NOT NULL,
    departure_city_lower     VARCHAR(255) GENERATED ALWAYS AS (LOWER(departure_city)) STORED,
    arrival_city_lower       VARCHAR(255) GENERATED ALWAYS AS (LOWER(arrival_city)) STORED,
    flight_date              DATE NOT NULL,
    flight_time              TIME,
    max_weight_kg            DECIMAL(6,2) NOT NULL CHECK (max_weight_kg > 0),
    price_per_kg             DECIMAL(8,2) NOT NULL CHECK (price_per_kg > 0),
    description              TEXT,
    status                   VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'expired')),
    total_packages_carried   INTEGER DEFAULT 0,
    created_at               TIMESTAMPTZ DEFAULT NOW(),
    updated_at               TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transport_ads_transporter ON transport_ads(transporter_id);
CREATE INDEX idx_transport_ads_status ON transport_ads(status);
CREATE INDEX idx_transport_ads_flight_date ON transport_ads(flight_date);
CREATE INDEX idx_transport_ads_departure ON transport_ads(departure_city_lower);
CREATE INDEX idx_transport_ads_arrival ON transport_ads(arrival_city_lower);

-- ─────────────────────────────────────────────────────────────
-- TRANSPORT REQUESTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE transport_requests (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firestore_id     VARCHAR(128) UNIQUE,
    ad_id            UUID NOT NULL REFERENCES transport_ads(id),
    transporter_id   UUID NOT NULL REFERENCES users(id),
    client_id        UUID NOT NULL REFERENCES users(id),
    message          TEXT,
    status           VARCHAR(20) DEFAULT 'PENDING'
                     CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')),
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ad_id, client_id)
);

CREATE INDEX idx_requests_transporter ON transport_requests(transporter_id);
CREATE INDEX idx_requests_client ON transport_requests(client_id);
CREATE INDEX idx_requests_status ON transport_requests(status);

-- ─────────────────────────────────────────────────────────────
-- TRANSPORT ORDERS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE transport_orders (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firestore_id        VARCHAR(128) UNIQUE,
    order_number        VARCHAR(20) UNIQUE NOT NULL,  -- e.g. TRP-2026-000145
    ad_id               UUID NOT NULL REFERENCES transport_ads(id),
    request_id          UUID NOT NULL REFERENCES transport_requests(id),
    transporter_id      UUID NOT NULL REFERENCES users(id),
    client_id           UUID NOT NULL REFERENCES users(id),
    departure_city      VARCHAR(255) NOT NULL,
    arrival_city        VARCHAR(255) NOT NULL,
    flight_date         DATE NOT NULL,
    price_per_kg        DECIMAL(8,2) NOT NULL,
    status              VARCHAR(20) DEFAULT 'ACCEPTED'
                        CHECK (status IN (
                          'PENDING', 'ACCEPTED', 'REJECTED',
                          'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
                        )),
    review_authorized   BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_transporter ON transport_orders(transporter_id);
CREATE INDEX idx_orders_client ON transport_orders(client_id);
CREATE INDEX idx_orders_status ON transport_orders(status);
CREATE INDEX idx_orders_number ON transport_orders(order_number);

-- ─────────────────────────────────────────────────────────────
-- CANCELLATIONS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE cancellations (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id     UUID NOT NULL REFERENCES transport_orders(id),
    author_id    UUID NOT NULL REFERENCES users(id),
    reason       TEXT NOT NULL,
    cancelled_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cancellations_order ON cancellations(order_id);

-- ─────────────────────────────────────────────────────────────
-- REVIEWS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE reviews (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firestore_id      VARCHAR(128) UNIQUE,
    order_id          UUID NOT NULL REFERENCES transport_orders(id),
    order_number      VARCHAR(20) NOT NULL,
    transporter_id    UUID NOT NULL REFERENCES users(id),
    client_id         UUID NOT NULL REFERENCES users(id),
    rating            DECIMAL(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment           TEXT,
    punctuality       DECIMAL(2,1) CHECK (punctuality >= 1 AND punctuality <= 5),
    communication     DECIMAL(2,1) CHECK (communication >= 1 AND communication <= 5),
    package_condition DECIMAL(2,1) CHECK (package_condition >= 1 AND package_condition <= 5),
    reliability       DECIMAL(2,1) CHECK (reliability >= 1 AND reliability <= 5),
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(order_id, client_id)
);

CREATE INDEX idx_reviews_transporter ON reviews(transporter_id);
CREATE INDEX idx_reviews_client ON reviews(client_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);

-- ─────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE notifications (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firestore_id VARCHAR(128) UNIQUE,
    user_id      UUID NOT NULL REFERENCES users(id),
    title        VARCHAR(255) NOT NULL,
    body         TEXT NOT NULL,
    type         VARCHAR(50) NOT NULL,
    related_id   VARCHAR(128),
    is_read      BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read);

-- ─────────────────────────────────────────────────────────────
-- COUNTERS (for order number generation backup)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE counters (
    name  VARCHAR(50) PRIMARY KEY,
    value INTEGER DEFAULT 0
);

INSERT INTO counters(name, value) VALUES ('transport_orders', 0);

-- ─────────────────────────────────────────────────────────────
-- FUNCTIONS & TRIGGERS
-- ─────────────────────────────────────────────────────────────

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ads_updated_at BEFORE UPDATE ON transport_ads
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_requests_updated_at BEFORE UPDATE ON transport_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON transport_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─────────────────────────────────────────────────────────────
-- VIEWS
-- ─────────────────────────────────────────────────────────────

-- Transporter statistics view
CREATE OR REPLACE VIEW transporter_stats AS
SELECT
    u.id              AS transporter_id,
    u.full_name,
    u.average_rating,
    u.total_reviews,
    COUNT(o.id)       AS total_orders,
    COUNT(CASE WHEN o.status = 'COMPLETED' THEN 1 END) AS completed_orders,
    COUNT(CASE WHEN o.status = 'CANCELLED' THEN 1 END) AS cancelled_orders,
    CASE
        WHEN COUNT(o.id) > 0
        THEN ROUND(
            COUNT(CASE WHEN o.status = 'COMPLETED' THEN 1 END)::DECIMAL
            / COUNT(o.id) * 100, 1
        )
        ELSE 0
    END AS success_rate_pct
FROM users u
LEFT JOIN transport_orders o ON o.transporter_id = u.id
WHERE u.role = 'transporter'
GROUP BY u.id, u.full_name, u.average_rating, u.total_reviews;
