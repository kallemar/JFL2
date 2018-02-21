ALTER TABLE player ADD COLUMN birthdate INTEGER;
ALTER TABLE player ADD COLUMN optionchoiceid INTEGER;


CREATE TABLE option(
	id      	INTEGER PRIMARY KEY AUTOINCREMENT,
	name    	VARCHAR(255)
);
INSERT INTO option (id, name) VALUES (1, 'Pelipaita');


DROP TABLE IF EXISTS optionchoice;
CREATE TABLE optionchoice(
	id      	INTEGER PRIMARY KEY AUTOINCREMENT,
	name    	VARCHAR(255),
    price       INTEGER, -- price is sum in € * fraction
    fraction    INTEGER DEFAULT 10000, --fraction to the price
	netvisorid  INTEGER,
	optionid    INTEGER	
);
INSERT INTO optionchoice (id, name, price, fraction, optionid) VALUES (-1, 'käytän viimekesäistä pelipaitaa',-100000, 10000, 1);
INSERT INTO optionchoice (id, name, optionid) VALUES (1,'116',1);
INSERT INTO optionchoice (id, name, optionid) VALUES (2,'128',1);
INSERT INTO optionchoice (id, name, optionid) VALUES (3,'140',1);
INSERT INTO optionchoice (id, name, optionid) VALUES (4,'152',1);
INSERT INTO optionchoice (id, name, optionid) VALUES (5,'164',1);
INSERT INTO optionchoice (id, name, optionid) VALUES (6,'S',1);
INSERT INTO optionchoice (id, name, optionid) VALUES (7,'M',1);
INSERT INTO optionchoice (id, name, optionid) VALUES (8,'L',1);


DROP TABLE IF EXISTS season_option;
CREATE TABLE season_option (
        seasonid  INTEGER,
        optionid  INTEGER,
        PRIMARY KEY(seasonid, optionid)
);
INSERT INTO season_option (seasonid, optionid) VALUES (9,1);
