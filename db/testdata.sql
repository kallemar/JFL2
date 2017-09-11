--insert active season
INSERT INTO season (name, startdate, enddate, isactive, price) VALUES('2014', strftime("%s", '2014-05-01'), strftime("%s", '2014-10-30'), 1, 850000);

--insert suburbans
INSERT INTO suburban (name, description, seasonid) VALUES("HALLILA", "Hallila, Jokipohja, Koivistonkylä, Korkinmäki, Nirva, Taatala, Veisu", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("HERVANTA", "Hervanta ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("HÄRMÄLÄ", "Härmälä, Pirkkala, Rantaperkiö, Toivio, Vihilahti" , 1);
INSERT INTO suburban (name, description, seasonid) VALUES("KALEVA", "Armonkallio, Järvensivu, Jussinkylä, Kaleva, Kalevankangas, Kauppi, Kissanmaa, Kyttälä, Lapinniemi, Lappi, Liisankallio, Osmonmäki, Petsamo, Ratina, Tammela ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("KAUKAJÄRVI", "Aakkula, Annala, Finninmäki, Kaukajärvi, Lukonmäki, Messukylä, Turtola, Viiala, Vuohenoja ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("KESKIKAUPUNKI", "Amuri, Keskikaupunki, Onkiniemi, Nalkala, Pyynikki ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("LENTÄVÄNNIEMI", "Lentävänniemi, Lielahti, Lintulampi, Niemi, Pohtola, Ryydynpohja, Siivikkala, Ylöjärvi ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("OLKAHINEN", "Atala, Kumpula, Kämmenniemi, Nurmi, Olkahinen, Sorila, Tasanne, Teisko, Terälahti ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("MULTISILTA (PELTOLAMMI)", "Höytämö, Lakalaiva, Lempäälä, Multisilta, Peltolammi ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("PISPALA", "Epilä, Epilänharju, Hyhky, Kaarila, Pispala, Tahmela", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("RUUTANA", "Kangasala, Ruutana, Suinula ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("TAKAHUHTI", "Hakametsä, Huikas, Janka, Linnainmaa, Pappila, Ristinarkku, Ruotula, Takahuhti, Uusikylä ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("TESOMA", "Haukiluoma, Ikuri, Kalkku, Lamminpää, Lintuviita, Nokia, Rahola, Tesoma, Tohloppi, Vuorentausta", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("VEHMAINEN", "Hankkio, Holvasti, Leinola, Vehmainen ", 1);
INSERT INTO suburban (name, description, seasonid) VALUES("VIINIKKA", "Nekala, Muotiala, Vihioja, Viinikka", 1);


INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Pentti","Peltonen","050-596 7170","peltonen.pentti@luukku.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Markku","Helenius","040-554 3407","makre.helenius@gmail.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Kari","Salmi","050-331 5257","k.salmi@luukku.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Ilkka","Vuorenmaa","040-561 8302","ilkka.vuorenmaa@iki.fi", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Tiina","Aaltonen","0400-591 668","tiina.aaltonen15@suomi24.fi", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Asta","Luukkonen","","asta.luukkonen@suomi24.fi", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Pertti","Numminen","0400-339 392","petu.numminen@hotmail.fi", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Jari","Mattila","050-540 9236","mattila.jk@gmail.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Juhani","Söderberg","040-809 5487","juhani.soderberg@pp.inet.fi", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Eero","Kempe","040-521 1444","Eero.Kempe@vero.fi", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Merja","Kuosmanen","050-344 7045","m_kuosmanen@hotmail.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Matti","Pispa","040-596 4951","matti.s.pispa@luukku.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Markku","Mäkelä","","050-574 5952", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Jouni","Kaikuranta","040-709 2027","jouni.kaikuranta@metso.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Heidi","Ekola","045-113 4087","heidiekola@hotmail.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Kati","Kopperoinen","050-584 2738","kati.kopperoinen@gmail.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Marko","Mäkinen","0400-625 709","markojuhani.makinen@gmail.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Tommi","Sairo","","tommi.sairo@gmail.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Pentti","Perämaa","050-348 1992","pentti.peramaa@luukku.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Ismo","Mattila","0500-632 757","ismo.mattila@artosta.fi", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Mari","Olanterä","040-544 0693","mtmo72@gmail.com", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Juhana","Karttunen","040-839 7976","juhana.karttunen@saunalahti.fi", 1);
INSERT INTO contact (firstname, lastname, phone, email, seasonid) VALUES("Maija","Kossila","050-554 3842","maija.kossila@nsn.com", 1);

