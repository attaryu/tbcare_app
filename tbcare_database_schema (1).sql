-- ============================================================
-- TBCare PostgreSQL Database Schema
-- ============================================================

CREATE TYPE treatment_status  AS ENUM ('active', 'completed', 'failed');
CREATE TYPE supervision_status AS ENUM ('pending', 'approved', 'rejected', 'revoked');
CREATE TYPE compliance_status  AS ENUM ('pending', 'taken', 'missed');
CREATE TYPE escalation_status  AS ENUM ('triggered', 'resolved', 'ignored');

-- ============================================================
-- STEP 1: Tables with no FK dependencies
-- ============================================================

CREATE TABLE roles (
    id      SERIAL PRIMARY KEY,
    slug    VARCHAR(100) NOT NULL UNIQUE,
    name    VARCHAR(255) NOT NULL
);

CREATE TABLE permissions (
    id      SERIAL PRIMARY KEY,
    slug    VARCHAR(100) NOT NULL UNIQUE,
    name    VARCHAR(255) NOT NULL
);

CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    fcm_token   VARCHAR(255)
);

-- ============================================================
-- STEP 2: Junction / child tables that depend on step 1
-- ============================================================

CREATE TABLE role_permissions (
    role_id       INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,

    PRIMARY KEY (role_id, permission_id),

    CONSTRAINT fk_rp_role
        FOREIGN KEY (role_id) REFERENCES roles (id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_rp_permission
        FOREIGN KEY (permission_id) REFERENCES permissions (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE user_roles (
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,

    PRIMARY KEY (user_id, role_id),

    CONSTRAINT fk_ur_user
        FOREIGN KEY (user_id) REFERENCES users (id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_ur_role
        FOREIGN KEY (role_id) REFERENCES roles (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE supervisions (
    id               SERIAL PRIMARY KEY,
    supervisor_id    INTEGER NOT NULL,
    supervision_code VARCHAR(100) UNIQUE,

    CONSTRAINT fk_supervisions_supervisor
        FOREIGN KEY (supervisor_id) REFERENCES users (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE treatment_periods (
    id          SERIAL PRIMARY KEY,
    patients_id INTEGER NOT NULL,
    start_date  DATE NOT NULL,
    end_date    DATE,
    status      treatment_status NOT NULL DEFAULT 'active',

    CONSTRAINT fk_treatment_periods_patient
        FOREIGN KEY (patients_id) REFERENCES users (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- STEP 3: Tables that depend on step 2
-- ============================================================

CREATE TABLE supervisions_patients (
    id             SERIAL PRIMARY KEY,
    supervision_id INTEGER NOT NULL,
    patients_id    INTEGER NOT NULL,
    status         supervision_status NOT NULL DEFAULT 'pending',
    joined_at      TIMESTAMP,
    request_at     TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_sp_supervision
        FOREIGN KEY (supervision_id) REFERENCES supervisions (id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_sp_patient
        FOREIGN KEY (patients_id) REFERENCES users (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE symptom_logs (
    id                  SERIAL PRIMARY KEY,
    treatment_period_id INTEGER NOT NULL,
    note                TEXT,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    edited_at           TIMESTAMP,

    CONSTRAINT fk_symptom_logs_treatment_period
        FOREIGN KEY (treatment_period_id) REFERENCES treatment_periods (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE medication_schedules (
    id                  SERIAL PRIMARY KEY,
    treatment_period_id INTEGER NOT NULL,
    med_name            VARCHAR(255) NOT NULL,
    schedule_time       TIME NOT NULL,

    CONSTRAINT fk_medication_schedules_treatment_period
        FOREIGN KEY (treatment_period_id) REFERENCES treatment_periods (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- STEP 4: Tables that depend on step 3
-- ============================================================

CREATE TABLE compliance_logs (
    id          SERIAL PRIMARY KEY,
    schedule_id INTEGER NOT NULL,
    photo_url   VARCHAR(500),
    taken_at    TIMESTAMP,
    status      compliance_status NOT NULL DEFAULT 'pending',
    verified_by INTEGER,

    CONSTRAINT fk_compliance_logs_schedule
        FOREIGN KEY (schedule_id) REFERENCES medication_schedules (id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_compliance_logs_verifier
        FOREIGN KEY (verified_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- ============================================================
-- STEP 5: Tables that depend on step 4
-- ============================================================

CREATE TABLE escalation_logs (
    id                SERIAL PRIMARY KEY,
    compliance_log_id INTEGER NOT NULL,
    status            escalation_status NOT NULL DEFAULT 'triggered',
    action_note       TEXT,
    handled_by        INTEGER,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    resolved_at       TIMESTAMP,

    CONSTRAINT fk_escalation_logs_compliance_log
        FOREIGN KEY (compliance_log_id) REFERENCES compliance_logs (id)
        ON DELETE CASCADE ON UPDATE CASCADE,

    CONSTRAINT fk_escalation_logs_handler
        FOREIGN KEY (handled_by) REFERENCES users (id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- ============================================================
-- Indexes untuk performa query
-- ============================================================

CREATE INDEX idx_user_roles_user_id          ON user_roles (user_id);
CREATE INDEX idx_user_roles_role_id          ON user_roles (role_id);
CREATE INDEX idx_role_permissions_role_id    ON role_permissions (role_id);
CREATE INDEX idx_role_permissions_perm_id    ON role_permissions (permission_id);
CREATE INDEX idx_supervisions_supervisor_id  ON supervisions (supervisor_id);
CREATE INDEX idx_sp_supervision_id           ON supervisions_patients (supervision_id);
CREATE INDEX idx_sp_patients_id              ON supervisions_patients (patients_id);
CREATE INDEX idx_treatment_periods_pat_id    ON treatment_periods (patients_id);
CREATE INDEX idx_symptom_logs_tp_id          ON symptom_logs (treatment_period_id);
CREATE INDEX idx_med_schedules_tp_id         ON medication_schedules (treatment_period_id);
CREATE INDEX idx_compliance_logs_sched_id    ON compliance_logs (schedule_id);
CREATE INDEX idx_compliance_logs_verified_by ON compliance_logs (verified_by);
CREATE INDEX idx_escalation_logs_comp_id     ON escalation_logs (compliance_log_id);
CREATE INDEX idx_escalation_logs_handled_by  ON escalation_logs (handled_by);