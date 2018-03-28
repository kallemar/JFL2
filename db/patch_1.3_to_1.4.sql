ALTER TABLE suburban ADD COLUMN price INTEGER;
ALTER TABLE suburban ADD COLUMN fraction INTEGER DEFAULT 10000;

ALTER TABLE player ADD COLUMN netvisorid_customer INTEGER;
ALTER TABLE player ADD COLUMN netvisorid_invoice INTEGER;
ALTER TABLE suburban ADD COLUMN netvisorid INTEGER;
ALTER TABLE season ADD COLUMN netvisorid INTEGER;

ALTER TABLE season ADD COLUMN netvisorid_product TEXT;
ALTER TABLE suburban ADD COLUMN netvisorid_product TEXT;

