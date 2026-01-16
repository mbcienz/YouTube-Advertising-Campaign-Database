/*SCRIPT DI CREAZIONE*/

/*creazione database*/
DROP DATABASE IF EXISTS basi_di_dati_gruppo_05;
CREATE DATABASE basi_di_dati_gruppo_05;

/*DROP delle tabelle*/
DROP TABLE IF EXISTS azienda CASCADE;
DROP TABLE IF EXISTS numero_di_telefono CASCADE;
DROP TABLE IF EXISTS campagna CASCADE;
DROP TABLE IF EXISTS video CASCADE;
DROP TABLE IF EXISTS kpi CASCADE;
DROP TABLE IF EXISTS monitoraggio CASCADE;
DROP TABLE IF EXISTS tag CASCADE;
DROP TABLE IF EXISTS v_t CASCADE;
DROP TABLE IF EXISTS utente CASCADE;
DROP TABLE IF EXISTS interazione CASCADE;
DROP TABLE IF EXISTS v_i CASCADE;

/*creazione tabella azienda*/
CREATE TABLE azienda (
    partita_iva  CHAR(11) PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    provincia VARCHAR(30),
    comune VARCHAR(30),
    nome_via VARCHAR(30),
    numero_civico INTEGER,
    cap char(5),
    indirizzo_email VARCHAR(70) UNIQUE,
    descrizione VARCHAR(300),
    CONSTRAINT check_partita_iva_azienda CHECK (CHAR_LENGTH(partita_iva)=11),
    CONSTRAINT check_cap_azienda CHECK(CHAR_LENGTH(cap)=5),
    CONSTRAINT check_sede_legale_azienda CHECK ( /*gli attributi della sede legale o ci sono tutti o nessuno*/
        (provincia IS NULL AND comune IS NULL AND cap IS NULL AND nome_via IS NULL AND numero_civico IS NULL)
        OR
        (provincia IS NOT NULL AND comune IS NOT NULL AND cap IS NOT NULL AND nome_via IS NOT NULL AND numero_civico IS NOT NULL)
    )
);

/*creazione tabella numero_di_telefono*/
CREATE TABLE numero_di_telefono(
    numero VARCHAR(30) PRIMARY KEY,
    partita_iva char(11) NOT NULL REFERENCES azienda(partita_iva) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT check_partita_iva_numero_di_telefono CHECK(CHAR_LENGTH(partita_iva)=11)
);

/*creazione tabella campagna*/
CREATE TABLE campagna(
    id INTEGER PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    data_inizio DATE NOT NULL,
    data_fine DATE,
    budget DECIMAL(8,2) NOT NULL,
    eta INTEGER,
    genere CHAR(1),
    descrizione VARCHAR(300),
    raggiungimento_obiettivo DECIMAL(3,2),
    partita_iva CHAR(11) NOT NULL REFERENCES azienda(partita_iva) ON DELETE RESTRICT ON UPDATE CASCADE
        DEFERRABLE INITIALLY DEFERRED, /*deferred per poter implementare il trigger di cardinalità minima dell'azienda*/
    id_video INTEGER NOT NULL UNIQUE,
    CONSTRAINT attributi_univoci UNIQUE (nome,data_inizio,partita_iva),
    CONSTRAINT check_budget_campagna CHECK(budget >= 0.00),
    CONSTRAINT check_eta_campagna CHECK(eta>=0),
    CONSTRAINT check_genere_campagna CHECK (genere='M' OR genere='F'),
    CONSTRAINT check_data_fine_campagna CHECK(data_fine >= data_inizio),
    CONSTRAINT check_raggiungimento_obiettivo_campagna CHECK (
        (data_fine IS NULL AND raggiungimento_obiettivo IS NULL)
        /*se data_fine è NULL allora raggiungimento_obiettivo deve essere NULL */
        OR (data_fine IS NOT NULL AND ((raggiungimento_obiettivo >= 0.00 AND raggiungimento_obiettivo <= 1.00) OR raggiungimento_obiettivo IS NULL))
        /*se data_fine non è NULL allora raggiungimento_obiettivo deve essere compreso tra 0 e 1 oppure deve essere NULL*/
    ),
    CONSTRAINT check_partita_iva_campagna CHECK(CHAR_LENGTH(partita_iva)=11),
    CONSTRAINT check_target_campagna CHECK ( /*gli attributi del target o ci sono tutti o nessuno*/
        (eta IS NULL AND genere IS NULL)
        OR
        (eta IS NOT NULL AND genere IS NOT NULL)
    )
);

/*creazione tabella video*/
CREATE TABLE video(
    id INTEGER PRIMARY KEY,
    url CHAR(43) NOT NULL UNIQUE,
    titolo VARCHAR(30) NOT NULL,
    descrizione VARCHAR(300),
    durata TIME NOT NULL,
    estensione VARCHAR(10),
    risoluzione VARCHAR(10),
    numero_visualizzazioni INTEGER NOT NULL,
    skip BOOLEAN NOT NULL,
    id_campagna INTEGER NOT NULL UNIQUE REFERENCES campagna(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT check_url_video CHECK(CHAR_LENGTH(url)=43),
    CONSTRAINT check_durata_video CHECK(durata >= '00:00:05' AND durata <= '00:03:00'),
    CONSTRAINT check_numero_visualizzazioni_video CHECK(numero_visualizzazioni >= 0)
);

/*aggiunta del vincolo di integrità referenziale alla tabella campagna verso video*/
ALTER TABLE campagna ADD CONSTRAINT fk_campagna_video
    FOREIGN KEY (id_video) REFERENCES video(id) ON DELETE RESTRICT ON UPDATE CASCADE
    DEFERRABLE INITIALLY DEFERRED;

/*creazione tabella kpi*/
CREATE TABLE kpi(
    nome VARCHAR(30) PRIMARY KEY,
    formula VARCHAR(100) NOT NULL,
    descrizione VARCHAR(300),
    tipo VARCHAR(10) NOT NULL,
    CONSTRAINT check_tipo_kpi CHECK (tipo='tecnico' OR tipo='economico')
);

/*creazione tabella monitoraggio*/
CREATE TABLE monitoraggio(
    nome_kpi VARCHAR(30) REFERENCES kpi(nome) ON DELETE CASCADE ON UPDATE CASCADE,
    id_video INTEGER REFERENCES video(id) ON DELETE CASCADE ON UPDATE CASCADE,
    valore DECIMAL(7,3) NOT NULL,
    CONSTRAINT pk_monitoraggio PRIMARY KEY(nome_kpi, id_video)
);

/*creazione tabella tag*/
CREATE TABLE tag(
    nome VARCHAR(30) PRIMARY KEY
);

/*creazione tabella v_t*/
CREATE TABLE v_t(
    id_video INTEGER REFERENCES video(id) ON DELETE CASCADE ON UPDATE CASCADE,
    nome_tag VARCHAR(30) REFERENCES tag(nome) ON DELETE CASCADE ON UPDATE CASCADE
        DEFERRABLE INITIALLY DEFERRED, /*deferred per poter implementare il trigger di cardinalità minima del tag*/
    CONSTRAINT pk_v_t PRIMARY KEY(id_video, nome_tag)
);

/*creazione tabella utente*/
CREATE TABLE utente(
    nickname VARCHAR(30) PRIMARY KEY,
    indirizzo_email VARCHAR(70) NOT NULL UNIQUE,
    nome VARCHAR(30) NOT NULL,
    cognome VARCHAR(30) NOT NULL,
    data_di_nascita DATE,
    numero_di_telefono VARCHAR(30),
    genere CHAR(1),
    CONSTRAINT check_genere_utente CHECK (genere='M' OR genere='F')
);

/*creazione tabella interazione*/
CREATE TABLE interazione(
    id INTEGER PRIMARY KEY,
    data_e_ora TIMESTAMP NOT NULL,
    tempo_di_visualizzazione TIME NOT NULL,
    click_su_skip BOOLEAN,
    click_su_video BOOLEAN NOT NULL,
    "like" BOOLEAN NOT NULL,
    condivisione BOOLEAN NOT NULL,
    nickname_utente VARCHAR(30) NOT NULL REFERENCES utente(nickname) ON DELETE RESTRICT ON UPDATE CASCADE
        DEFERRABLE INITIALLY DEFERRED /*deferred per poter implementare il trigger di cardinalità minima dell'utente*/
);

/*creazione tabella v_i*/
CREATE TABLE v_i(
    id_interazione INTEGER PRIMARY KEY REFERENCES interazione(id) ON DELETE CASCADE ON UPDATE CASCADE,
    id_video INTEGER NOT NULL REFERENCES video(id) ON DELETE CASCADE ON UPDATE CASCADE
);

/*aggiunta del vincolo di integrità referenziale alla tabella interazione verso v_i*/
ALTER TABLE interazione ADD CONSTRAINT fk_interazione_v_i
    FOREIGN KEY (id) REFERENCES v_i(id_interazione) ON DELETE CASCADE ON UPDATE RESTRICT
    DEFERRABLE INITIALLY DEFERRED;

/*---------------------------------------------------------------------------------------------------------------------------------------*/

/*SCRIPT DI POPOLAMENTO*/

BEGIN TRANSACTION;
/*popolamento campagna*/
INSERT INTO campagna(id, nome, data_inizio, data_fine, budget, eta, genere, descrizione, raggiungimento_obiettivo, partita_iva, id_video) VALUES
(1, 'Presentazione Singolo', '2023-06-09', NULL, 10000.00, 17, 'M', NULL, NULL, '12345678901', 1),
(2, 'Lancio nuovo modello Piaggio', '2023-05-20', NULL, 150000.00, 18, 'F', NULL, NULL, '11145672345', 2),
(3, 'Lancio nuovi Spot, robotica per il lavoro', '2023-05-30', NULL, 5000.00, 37, 'M', NULL, NULL, '25678274560', 3),
(4, 'La capacità della nostra AI', '2023-05-15', NULL, 120000.00, 15, 'M', NULL, NULL, '45623456789', 4),
(5, 'Costruzioni 3d a basso costo', '2023-04-10', NULL, 13000.00, NULL, NULL, 'materiale per la stampa 3d', NULL, '56734590122', 5),
(6, 'Costruzioni 3d ad alto costo', '2023-07-10', '2023-07-20', 13000.00, NULL, NULL, 'materiale per la stampa 3d', 0.9, '56734590122', 6);

/*popolamento azienda*/
INSERT INTO azienda(partita_iva, nome, provincia, comune, nome_via, numero_civico, cap, indirizzo_email, descrizione) VALUES
('12345678901', 'PincoPal', 'SA', 'Nocera Inferiore', 'Vittorio Emanuele III', 33, '84014', 'business@pincopal.it', NULL),
('25678274560', 'FrancoSRL', 'SA', 'Pagani', 'Corso', 82, '84015', 'produzione@francosrl.it', NULL),
('11145672345', 'Piaggio', NULL, NULL, NULL, NULL, NULL, 'commercial@piaggio.it', 'Storica azienda produttrice di motocicli'),
('45623456789', 'Google Italia', NULL, NULL, NULL, NULL, NULL, 'googleitalia@google.it', NULL),
('56734590122', 'LibriINC', 'MI', 'Milano', 'StradaMilanese', 123, '20019', 'annunci@libriinc.it', 'Grande azienda di produzione cartacea');

/*popolamento video*/
INSERT INTO video(id, url, titolo, descrizione, durata, estensione, risoluzione, numero_visualizzazioni, skip, id_campagna) VALUES
(1, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', 'Never Gonna Give You Up', NULL, '00:00:30', '.mp4', '1920x1080', 4, TRUE, 1),
(2, 'https://www.youtube.com/watch?v=OCMnrsxTbEs', 'PiaggioSpot', 'Spot piaggio', '00:01:45', '.mp4', '240p', 4, TRUE, 2),
(3, 'https://www.youtube.com/watch?v=qgHeCfMa39E', 'Boston Dynamics', 'The industry standard for dangerous and routine autonomous inspections just got better', '00:01:45', '.mp4', '4k', 5, FALSE, 3),
(4, 'https://www.youtube.com/watch?v=VKEA5cJluc0', 'NVIDIA AI', 'Voyager: An Open-Ended Embodied Agent with Large Language Models', '00:02:30', '.mp4', '1920x1080', 3, TRUE, 4),
(5, 'https://www.youtube.com/watch?v=qe5mvO7vF4Y', 'Material for 3d printing', 'composite materials and electroplating' , '00:02:59', '.mp4', '1920x1080', 2, FALSE, 5),
(6, 'https://www.youtube.com/watch?v=qe5mvO7vT9Y', 'Material for 3d printing', 'composite materials and electroplating' , '00:02:59', '.mp4', '1920x1080', 2, FALSE, 6);
COMMIT;

/*popolamento numero di telefono*/
INSERT INTO numero_di_telefono(numero, partita_iva) VALUES
('3403344516', '12345678901'),
('3385613368', '25678274560'),
('3346783367', '25678274560'),
('3409906654', '25678274560'),
('3472233345', '11145672345'),
('3392468456', '11145672345'),
('3346667897', '56734590122'),
('3394363748', '56734590122');

BEGIN TRANSACTION;
/*popolamento v_t*/
INSERT INTO v_t(id_video, nome_tag) VALUES
(1, 'musica'),
(3, 'tecnologia'),
(3, 'engineering'),
(3, 'ai'),
(3, 'robot'),
(2, 'meccanica'),
(2, 'engineering'),
(2, 'italia'),
(5, '3d'),
(5, 'engineering'),
(5, 'tecnologia'),
(4, 'papers'),
(4, 'engineering'),
(4, 'tecnologia');

/*popolamento tag*/
INSERT INTO tag(nome) VALUES
('musica'),
('tecnologia'),
('3d'),
('engineering'),
('meccanica'),
('italia'),
('robot'),
('ai'),
('papers');
COMMIT;

/*popolamento kpi*/
INSERT INTO  kpi(nome, formula, descrizione, tipo) VALUES
('Reach', 'numero di utenti unici che hanno visualizzato il video', 'indica il numero di utenti che hanno visto il video almeno una volta durante il ciclo di vita della campagna', 'tecnico'),
('Frequency', 'visualizzazioni/reach', 'indica il numero medio di volte che un singolo utente ha visualizzato quel video', 'tecnico'),
('Visualizzazione Completa', '(visualizzazioni complete / visualizzazioni) * 100', 'indica la percentuale di utenti che hanno guardato il video per intero', 'tecnico'),
('Skip', 'numero di volte che il video è stato saltato', 'indica il numero di volte che il video è stato saltato dagli utenti', 'tecnico'),
('Costo per Click', 'budget/numero click', 'indica il costo medio per ogni click generato dal video', 'economico'),
('Costo per like', 'budget/numero like', 'indica il costo medio per ottenere un like sul tuo video', 'economico'),
('Costo per condivisione', 'budget/numero condivisioni', 'indica il costo medio per ottenere una condivisione del tuo video', 'economico');

/*popolamento monitoraggio*/
INSERT INTO monitoraggio(nome_kpi, id_video, valore) values
('Reach', 1, 500.00),
('Reach', 2, 347.00),
('Reach', 3, 142.00),
('Reach', 4, 243.00),
('Reach', 5, 111.00),
('Frequency', 1, 12.34),
('Frequency', 2, 55.34),
('Skip', 1, 12.00),
('Skip', 2, 235.00),
('Skip', 4, 143.00),
('Costo per Click', 3, 0.12),
('Costo per Click', 5, 1.00),
('Costo per Click', 1, 0.05);

BEGIN TRANSACTION;
/*popolamento interazione*/
INSERT INTO interazione(id, data_e_ora, tempo_di_visualizzazione, click_su_skip, click_su_video, "like", condivisione, nickname_utente) VALUES
(1, '2023-04-15;10:43:57', '00:02:59', NULL, FALSE, FALSE, FALSE, 'enzosong'), /*video5 no skip*/
(2, '2023-05-01;18:22:12', '00:02:59', NULL, TRUE, TRUE, FALSE, 'enzosong'), 
(3, '2023-06-09;09:40:12', '00:00:07', TRUE, FALSE, FALSE, FALSE, 'lucapro'),/*video1*/
(4, '2023-06-10;11:25:45', '00:00:05', TRUE, FALSE, FALSE, FALSE, 'lucapro'),
(5, '2023-06-10;23:12:33', '00:00:12', TRUE, FALSE, FALSE, FALSE, 'paolofootball'),
(6, '2023-06-10;16:34:11', '00:00:30', FALSE, TRUE, TRUE, TRUE, 'mariachiarissima'),
(7, '2023-05-22;20:13:31', '00:00:30', TRUE, FALSE, TRUE, FALSE, 'alzu991'),/*video2*/
(8, '2023-05-26;11:15:15', '00:01:45', FALSE, TRUE, TRUE, TRUE, 'giornogiovanna'),
(9, '2023-05-27;16:46:11', '00:00:40', TRUE, FALSE, TRUE, TRUE, 'xXDarkAngelcraftXx'),
(10, '2023-06-01;22:22:22', '00:01:45', FALSE, TRUE, TRUE, FALSE, 'michelepizza99'),
(11, '2023-05-30;05:13:33', '00:01:45', NULL, TRUE, TRUE, FALSE, 'enzosong'),/*video3 no skip*/
(12, '2023-05-31;10:22:35', '00:01:45', NULL, TRUE, FALSE, FALSE, 'alzu991'),
(13, '2023-06-02;14:42:23', '00:01:45', NULL, FALSE, FALSE, FALSE, 'michelepizza99'),
(14, '2023-06-05;08:46:29', '00:01:45', NULL, FALSE, TRUE, FALSE, 'mariachiarissima'),
(15, '2023-06-10;13:37:00', '00:01:45', NULL, TRUE, TRUE, TRUE, 'lucapro'),
(16, '2023-05-15;17:32:12', '00:00:05', TRUE, FALSE, FALSE, FALSE, 'paolofootball'), /*video 4*/
(17, '2023-05-18;22:56:57', '00:02:30', FALSE, FALSE, TRUE, FALSE, 'mariachiarissima'),
(18, '2023-06-07;18:59:31', '00:02:30', FALSE, TRUE, TRUE, TRUE, 'lucapro');

/*popolamento utente*/
INSERT INTO utente(nickname, indirizzo_email, nome, cognome, data_di_nascita, numero_di_telefono, genere) VALUES
('enzosong', 'es@gmail.com', 'vincenzo', 'capaldo', '2001-07-28', '3334445567', 'M'),
('lucapro', 'lp@gmail.com', 'luca', 'donnarumma', '2001-06-12', '3345678907', 'M'),
('paolofootball', 'pf@gmail.com', 'paolo', 'esposito', '2001-06-23', '3457563213', 'M'),
('mariachiarissima', 'mc@gmail.com', 'mariachiara', 'garofalo', '2001-02-28', '3425366677', 'F'),
('xXDarkAngelcraftXx', 'darkcraft@libero.it', 'piero', 'valentino', '1995-05-05', '4445556677', 'M'),
('giornogiovanna', 'gg@gmail.com', 'giovanna', 'giorno', '2002-12-12', '3334410987', 'F'),
('michelepizza99', 'mp@libero.it', 'michele', 'ostuni', NULL, NULL, 'M'),
('alzu991', 'alzu@virgilio.it', 'alessandra', 'zuola', NULL, NULL, 'F');

/*popolamento v_i*/
INSERT INTO v_i(id_interazione, id_video) VALUES
(1, 5),
(2, 5),
(3, 1),
(4, 1),
(5, 1),
(6, 1),
(7, 2),
(8, 2),
(9, 2),
(10, 2),
(11, 3),
(12, 3),
(13, 3),
(14, 3),
(15, 3),
(16, 4),
(17, 4),
(18, 4);
COMMIT;

/*terminazione campagne*/
UPDATE campagna set data_fine = '2023-06-10', raggiungimento_obiettivo = 0.80 WHERE id = 2;
UPDATE campagna set data_fine = '2023-06-09', raggiungimento_obiettivo = 0.57 WHERE id = 4;
UPDATE campagna set data_fine = '2023-05-10', raggiungimento_obiettivo = 0.69 WHERE id = 5;