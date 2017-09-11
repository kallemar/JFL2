ALTER TABLE player ADD COLUMN license INTEGER;
ALTER TABLE users RENAME TO users_old;
CREATE TABLE users (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    created     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    username    VARCHAR(255) NOT NULL,
    password    VARCHAR(255) NOT NULL,
    firstname   VARCHAR(255),
    lastname    VARCHAR(255),
    phone       VARCHAR(255),
    contactid   INTEGER,
    coachid     INTEGER,
    sendmail    INTEGER DEFAULT 1, --0 don't send, 1 send mail
    FOREIGN KEY(contactid) REFERENCES contact(id),
    FOREIGN KEY(coachid) REFERENCES coach(id)
);
INSERT INTO users (id, created, username, password, firstname, lastname, phone, contactid, coachid, sendmail)
   SELECT id, created, username, password, firstname, lastname, phone, contactid, coachid, sendmail FROM users_old;
