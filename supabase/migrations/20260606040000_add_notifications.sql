-- Migration to add notification_type enum and notifications table
CREATE TYPE notification_type AS ENUM (
  'medication_proof_submitted',
  'medication_proof_confirmed',
  'medication_proof_rejected',
  'supervision_requested',
  'supervision_accepted',
  'supervision_rejected'
);

CREATE TABLE notifications (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receiver_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_id     INTEGER REFERENCES users(id) ON DELETE SET NULL,
  type          notification_type NOT NULL,
  title         VARCHAR(255) NOT NULL,
  body          TEXT NOT NULL,
  related_id    INTEGER,
  related_table VARCHAR(50),
  is_read       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_receiver ON notifications(receiver_id, created_at DESC);
