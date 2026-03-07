-- ============================================================
-- Neara Platform — Supabase Schema Migration
-- Run this in the Supabase SQL Editor (or as a migration file)
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. USERS (auth extension — profile data)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  phone       TEXT,
  email       TEXT,
  role        TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'worker', 'admin')),
  profile_image TEXT,
  latitude    DOUBLE PRECISION,
  longitude   DOUBLE PRECISION,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- 2. WORKERS (profile extension for role = 'worker')
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.workers (
  id                  SERIAL PRIMARY KEY,
  user_id             UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  category            TEXT NOT NULL,
  experience_years    INT NOT NULL DEFAULT 0,
  rating              NUMERIC(3,1) DEFAULT 5.0 CHECK (rating BETWEEN 1.0 AND 5.0),
  total_jobs          INT DEFAULT 0,
  is_verified         BOOLEAN DEFAULT FALSE,
  is_online           BOOLEAN DEFAULT FALSE,
  latitude            DOUBLE PRECISION,
  longitude           DOUBLE PRECISION,
  service_radius_km   NUMERIC(5,1) DEFAULT 10.0,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workers_category    ON public.workers (category);
CREATE INDEX IF NOT EXISTS idx_workers_is_online   ON public.workers (is_online);
CREATE INDEX IF NOT EXISTS idx_workers_user_id     ON public.workers (user_id);

-- ─────────────────────────────────────────────────────────────
-- 3. SERVICE REQUESTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.service_requests (
  id                SERIAL PRIMARY KEY,
  customer_id       UUID NOT NULL REFERENCES public.users(id),
  worker_id         INT  NOT NULL REFERENCES public.workers(id),
  service_category  TEXT NOT NULL,
  issue_summary     TEXT NOT NULL,
  urgency           TEXT NOT NULL DEFAULT 'medium' CHECK (urgency IN ('low', 'medium', 'high', 'emergency')),
  status            TEXT NOT NULL DEFAULT 'CREATED' CHECK (
                      status IN (
                        'CREATED', 'PENDING', 'MATCHING',
                        'PROPOSAL_SENT', 'NEGOTIATING', 'PROPOSAL_ACCEPTED',
                        'ADVANCE_PAID', 'WORKER_COMING', 'WORKER_ARRIVED',
                        'SERVICE_STARTED', 'SERVICE_COMPLETED',
                        'FINAL_PAYMENT_PENDING', 'SERVICE_CLOSED',
                        'PAYMENT_DONE', 'RATED', 'CANCELLED'
                      )
                    ),
  latitude          DOUBLE PRECISION,
  longitude         DOUBLE PRECISION,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_service_requests_customer  ON public.service_requests (customer_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_worker    ON public.service_requests (worker_id);
CREATE INDEX IF NOT EXISTS idx_service_requests_status    ON public.service_requests (status);

-- ─────────────────────────────────────────────────────────────
-- 4. PROPOSALS (worker bids on a service request)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.proposals (
  id              SERIAL PRIMARY KEY,
  request_id      INT  NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
  worker_id       INT  NOT NULL REFERENCES public.workers(id),
  inspection_fee  NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  service_cost    NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  advance_percent NUMERIC(5,2)  NOT NULL DEFAULT 50.00 CHECK (advance_percent BETWEEN 0 AND 100),
  estimated_time  TEXT,
  notes           TEXT,
  status          TEXT NOT NULL DEFAULT 'PENDING' CHECK (
                    status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'NEGOTIATING', 'COUNTERED', 'EXPIRED')
                  ),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_proposals_request  ON public.proposals (request_id);
CREATE INDEX IF NOT EXISTS idx_proposals_worker   ON public.proposals (worker_id);
CREATE INDEX IF NOT EXISTS idx_proposals_status   ON public.proposals (status);

-- ─────────────────────────────────────────────────────────────
-- 5. NEGOTIATIONS (counter-offer threads)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.negotiations (
  id              SERIAL PRIMARY KEY,
  proposal_id     INT  NOT NULL REFERENCES public.proposals(id) ON DELETE CASCADE,
  request_id      INT  NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
  sender_role     TEXT NOT NULL CHECK (sender_role IN ('customer', 'worker')),
  counter_amount  NUMERIC(10,2),
  message         TEXT NOT NULL,
  status          TEXT NOT NULL DEFAULT 'PENDING' CHECK (
                    status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'SUPERSEDED')
                  ),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_negotiations_proposal   ON public.negotiations (proposal_id);
CREATE INDEX IF NOT EXISTS idx_negotiations_request    ON public.negotiations (request_id);

-- ─────────────────────────────────────────────────────────────
-- 6. ESCROW PAYMENTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.escrow_payments (
  id                      SERIAL PRIMARY KEY,
  request_id              INT  NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
  customer_id             UUID NOT NULL REFERENCES public.users(id),
  worker_id               INT  NOT NULL REFERENCES public.workers(id),
  advance_amount          NUMERIC(10,2) NOT NULL,
  balance_amount          NUMERIC(10,2) NOT NULL,
  total_amount            NUMERIC(10,2) NOT NULL,
  escrow_status           TEXT NOT NULL DEFAULT 'HELD' CHECK (
                            escrow_status IN ('HELD', 'PARTIALLY_RELEASED', 'RELEASED', 'REFUNDED')
                          ),
  payment_method          TEXT DEFAULT 'MOCK',
  advance_transaction_id  TEXT,
  balance_transaction_id  TEXT,
  advance_paid_at         TIMESTAMPTZ,
  balance_paid_at         TIMESTAMPTZ,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_escrow_request_unique ON public.escrow_payments (request_id);
CREATE INDEX IF NOT EXISTS idx_escrow_customer ON public.escrow_payments (customer_id);
CREATE INDEX IF NOT EXISTS idx_escrow_worker   ON public.escrow_payments (worker_id);

-- ─────────────────────────────────────────────────────────────
-- 7. REVIEWS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reviews (
  id          SERIAL PRIMARY KEY,
  request_id  INT  NOT NULL REFERENCES public.service_requests(id) ON DELETE CASCADE,
  worker_id   INT  NOT NULL REFERENCES public.workers(id),
  customer_id UUID NOT NULL REFERENCES public.users(id),
  rating      INT  NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reviews_worker    ON public.reviews (worker_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer  ON public.reviews (customer_id);

-- ─────────────────────────────────────────────────────────────
-- 8. EMERGENCY CONTACTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.emergency_contacts (
  id            SERIAL PRIMARY KEY,
  user_id       UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  phone         TEXT NOT NULL,
  relationship  TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user ON public.emergency_contacts (user_id);

-- ─────────────────────────────────────────────────────────────
-- 9. SOS EVENTS
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sos_events (
  id              SERIAL PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES public.users(id),
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  status          TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'RESOLVED', 'FALSE_ALARM')),
  description     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────
-- 10. HELPER: auto-update updated_at timestamps
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trg_service_requests_updated_at
  BEFORE UPDATE ON public.service_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trg_proposals_updated_at
  BEFORE UPDATE ON public.proposals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─────────────────────────────────────────────────────────────
-- 11. ROW LEVEL SECURITY (RLS)
-- ─────────────────────────────────────────────────────────────

-- Enable RLS
ALTER TABLE public.users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workers            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_requests   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proposals          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.negotiations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_payments    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sos_events         ENABLE ROW LEVEL SECURITY;

-- Users: can read all profiles, edit only own
CREATE POLICY "users_read_all"   ON public.users FOR SELECT USING (true);
CREATE POLICY "users_edit_own"   ON public.users FOR UPDATE USING (auth.uid() = id);

-- Workers: public read
CREATE POLICY "workers_read_all" ON public.workers FOR SELECT USING (true);
CREATE POLICY "workers_edit_own" ON public.workers FOR UPDATE
  USING (user_id = auth.uid());

-- Service requests: customer sees own, worker sees assigned
CREATE POLICY "sr_customer_own" ON public.service_requests FOR ALL
  USING (customer_id = auth.uid());
CREATE POLICY "sr_worker_assigned" ON public.service_requests FOR SELECT
  USING (
    worker_id IN (
      SELECT id FROM public.workers WHERE user_id = auth.uid()
    )
  );

-- Proposals: worker sees own proposals, customer sees proposals on own requests
CREATE POLICY "proposals_worker_own" ON public.proposals FOR ALL
  USING (
    worker_id IN (
      SELECT id FROM public.workers WHERE user_id = auth.uid()
    )
  );
CREATE POLICY "proposals_customer_view" ON public.proposals FOR SELECT
  USING (
    request_id IN (
      SELECT id FROM public.service_requests WHERE customer_id = auth.uid()
    )
  );

-- Negotiations: parties can read/write
CREATE POLICY "negotiations_access" ON public.negotiations FOR ALL
  USING (
    request_id IN (
      SELECT id FROM public.service_requests
      WHERE customer_id = auth.uid()
    )
    OR
    proposal_id IN (
      SELECT id FROM public.proposals
      WHERE worker_id IN (
        SELECT id FROM public.workers WHERE user_id = auth.uid()
      )
    )
  );

-- Escrow payments: customer and assigned worker can read
CREATE POLICY "escrow_customer_read" ON public.escrow_payments FOR ALL
  USING (customer_id = auth.uid());
CREATE POLICY "escrow_worker_read" ON public.escrow_payments FOR SELECT
  USING (
    worker_id IN (
      SELECT id FROM public.workers WHERE user_id = auth.uid()
    )
  );

-- Reviews: customer owns, worker can read own reviews
CREATE POLICY "reviews_customer_own" ON public.reviews FOR ALL
  USING (customer_id = auth.uid());
CREATE POLICY "reviews_worker_read" ON public.reviews FOR SELECT
  USING (
    worker_id IN (
      SELECT id FROM public.workers WHERE user_id = auth.uid()
    )
  );

-- Emergency contacts: own
CREATE POLICY "emergency_contacts_own" ON public.emergency_contacts FOR ALL
  USING (user_id = auth.uid());

-- SOS events: own
CREATE POLICY "sos_events_own" ON public.sos_events FOR ALL
  USING (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────
-- 12. REALTIME PUBLICATION (enable for live updates)
-- ─────────────────────────────────────────────────────────────
-- Run separately if needed, or via Supabase dashboard:
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.service_requests;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.proposals;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.negotiations;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.escrow_payments;
