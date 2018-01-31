DROP TABLE IF EXISTS season;
DROP TABLE IF EXISTS player;
DROP TABLE IF EXISTS parent;
DROP TABLE IF EXISTS player_parent;
DROP TABLE IF EXISTS coach;
DROP TABLE IF EXISTS contact;
DROP TABLE IF EXISTS suburban;
DROP TABLE IF EXISTS team;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS contact_suburban;
DROP TABLE IF EXISTS shirtsizetable;

CREATE TABLE season (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    startdate   INTEGER,
    enddate     INTEGER,
    isactive    BOOLEAN,
    price       INTEGER, -- price is sum in € * fraction
    fraction    INTEGER DEFAULT 10000 --fraction to the price
);

CREATE TABLE player (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    firstname   VARCHAR(255) NOT NULL,
    lastname    VARCHAR(255) NOT NULL,
    hetu        VARCHAR(11)  NOT NULL,
    street      VARCHAR(255) NOT NULL,
    zip         VARCHAR(5)   NOT NULL,
    city        VARCHAR(255) NOT NULL,
    phone       VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL,
    refno       VARCHAR(24),
    number      INTEGER,
    birthyear   INTEGER,
    sex         INTEGER, -- 1 = girl, 2 = boy
    invoiced    INTEGER,
    paid        INTEGER,
    cancelled   INTEGER,
    license     INTEGER,
    isinvoice   INTEGER NOT NULL DEFAULT 1,
	wantstoplayingirlteam  INTEGER NOT NULL DEFAULT 0,  --1 wants to play in girl team, 0=don't want
    suburbanid  INTEGER REFERENCES suburbans(id),
    teamid      INTEGER REFERENCES teams(id),
    seasonid    INTEGER,
    shirtsizeid  INTEGER,
	cancelmsgsent INTEGER DEFAULT 0, -- 1 = sent, 0 = not sent
    FOREIGN KEY(seasonid) REFERENCES season(id)
);

CREATE TABLE parent (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    firstname   VARCHAR(255) NOT NULL,
    lastname    VARCHAR(255) NOT NULL,
    phone       VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL,
    relation    VARCHAR(255),
    interest    VARCHAR(255),
    comment     VARCHAR(255)

);

CREATE TABLE player_parent (
    playerid INTEGER REFERENCES player(id),
    parentid INTEGER REFERENCES parent(id)
);

CREATE TABLE coach (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    firstname   VARCHAR(255) NOT NULL,
    lastname    VARCHAR(255) NOT NULL,
    number      INTEGER, --player number in the shirt
    street      VARCHAR(255) NOT NULL,
    zip         VARCHAR(5)   NOT NULL,
    city        VARCHAR(255) NOT NULL,
    phone       VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL,
    suburbanid  INTEGER REFERENCES suburban(id),
    teamid      INTEGER REFERENCES team(id),
    seasonid    INTEGER,
    FOREIGN KEY(seasonid) REFERENCES season(id)
);

CREATE TABLE contact (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    firstname   VARCHAR(255) NOT NULL,
    lastname    VARCHAR(255) NOT NULL,
    street      VARCHAR(255),
    zip         VARCHAR(5),
    city        VARCHAR(255),
    phone       VARCHAR(255) NOT NULL,
    email       VARCHAR(255) NOT NULL,
    seasonid    INTEGER,
    FOREIGN KEY(seasonid) REFERENCES season(id)
);

CREATE TABLE suburban (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    price       INTEGER,
    fraction    INTEGER DEFAULT 10000,
    seasonid    INTEGER,
    isvisible   INTEGER NOT NULL DEFAULT 1,
    price       INTEGER, -- price is sum in € * fraction
    fraction    INTEGER DEFAULT 10000 --fraction to the price
    FOREIGN KEY(seasonid) REFERENCES season(id)
);

CREATE TABLE contact_suburban (
        contactid  INTEGER,
        suburbanid  INTEGER,
        PRIMARY KEY(contactid, suburbanid)
);

CREATE TABLE team (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    suburbanid  INTEGER,
    seasonid    INTEGER,
    FOREIGN KEY(suburbanid) REFERENCES suburban(id),
    FOREIGN KEY(seasonid) REFERENCES season(id)
);

CREATE TABLE roles (
        id    INTEGER     AUTO_INCREMENT PRIMARY KEY,
        role  VARCHAR(32) NOT NULL
);
--insert default roles to database
INSERT INTO roles (id, role) VALUES (1, 'admin');
INSERT INTO roles (id, role) VALUES (2, 'contact');
INSERT INTO roles (id, role) VALUES (3, 'coach');


CREATE TABLE users (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    username    VARCHAR(32) NOT NULL,
    password    VARCHAR(40) NOT NULL,
    firstname   VARCHAR(255),
    lastname    VARCHAR(255),
    phone       VARCHAR(255),
    contactid   INTEGER,
    coachid     INTEGER,
    sendmail    INTEGER DEFAULT 1, --0 don't send, 1 send mail
    FOREIGN KEY(contactid) REFERENCES contact(id),
    FOREIGN KEY(coachid) REFERENCES coach(id)
);
--insert default system user to database. Password is admin
INSERT INTO users (username, password, firstname, lastname, phone)
       VALUES("admin@futisklubi.tpv.fi", "{SSHA}HGyn3rVEOTs8Fd6UPqbJi6eV0mPgiZy7", "Firstname", "Lastname", "000 123 4567");


CREATE TABLE user_roles (
        user_id  INTEGER,
        role_id  INTEGER,
        PRIMARY KEY(user_id, role_id)
);
--add admin to admin role
INSERT INTO user_roles (user_id, role_id) VALUES (1,1);

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
