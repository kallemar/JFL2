ALTER TABLE player ADD COLUMN shirtsizeid INTEGER;
ALTER TABLE player ADD COLUMN wantstoplayingirlteam  INTEGER NOT NULL DEFAULT 0;
ALTER TABLE player ADD COLUMN cancelmsgsent INTEGER DEFAULT 0;

UPDATE player SET cancelmsgsent=1 WHERE seasonid=5 AND cancelled IS NOT NULL;

--SHIRT SIZES
CREATE TABLE shirtsizetable(
	id      INTEGER PRIMARY KEY AUTOINCREMENT,
	name    VARCHAR(255)
);
INSERT INTO shirtsizetable (id, name) VALUES (-1, 'käytän viimekesäistä pelipaitaa');
INSERT INTO shirtsizetable (id, name) VALUES (1,'116');
INSERT INTO shirtsizetable (id, name) VALUES (2,'128');
INSERT INTO shirtsizetable (id, name) VALUES (3,'140');
INSERT INTO shirtsizetable (id, name) VALUES (4,'152');
INSERT INTO shirtsizetable (id, name) VALUES (5,'164');
INSERT INTO shirtsizetable (id, name) VALUES (6,'S');
INSERT INTO shirtsizetable (id, name) VALUES (7,'M');
INSERT INTO shirtsizetable (id, name) VALUES (8,'L');
