-- Inspection dates may precede 1970 or follow 2038; TIMESTAMP cannot store that range.
ALTER TABLE field_notes MODIFY date_time DATETIME(6) NULL;
