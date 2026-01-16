/* 9.1.	Trigger inizializzazione: v_i e proteggi_numero_studenti */
create or replace function v_i() returns trigger as $$
begin
    if(new is not null) then
        update video set numero_visualizzazioni=1 where id = new.id_video;
    end if;
    if(old is not null) then
        update video set numero_visualizzazioni=1 where id=old.id_video;
    end if;
    return null;
end
$$ language plpgsql;

create trigger v_i
after insert or delete or update on v_i
for each row
execute function v_i();

create or replace function proteggi_numero_visualizzazioni() returns trigger as $$
begin
    select count(*) into new.numero_visualizzazioni
    from v_i
    where id_video = new.id;
    return new;
end
$$ language plpgsql;

create trigger proteggi_numero_visualizzazioni
before insert or update of numero_visualizzazioni on video
for each row
execute function proteggi_numero_visualizzazioni();

/* 9.2.	Trigger per vincoli aziendali */
/* 9.2.1. Trigger1: verifica_v_i e verifica_update_interazione */
CREATE OR REPLACE FUNCTION verifica_v_i() RETURNS TRIGGER AS $$
DECLARE
    controllo_data_inizio DATE;
	controllo_data_fine DATE;
	data_interazione DATE;
	
	durata_interazione TIME;
    durata_video TIME;
		
	skip_interazione BOOL;
    skip_video BOOL;

BEGIN
   	SELECT data_inizio INTO controllo_data_inizio
	FROM campagna
	WHERE id_video = NEW.id_video;
	
	SELECT data_fine INTO controllo_data_fine
	FROM campagna
	WHERE id_video = NEW.id_video;
	
	SELECT data_e_ora INTO data_interazione
	FROM interazione
	WHERE id = NEW.id_interazione;

	IF (controllo_data_fine IS NOT NULL) THEN
        RAISE EXCEPTION 'Il video associato all''interazione non appartiene ad una campagna corrente.';
	END IF;
	
	IF (data_interazione < controllo_data_inizio) THEN
        RAISE EXCEPTION 'La data dell''interazione deve essere maggiore o uguale alla data di inizio della campagna.';
	END IF;

	SELECT tempo_di_visualizzazione INTO durata_interazione
	FROM interazione
	WHERE interazione.id = NEW.id_interazione;
	
	SELECT durata INTO durata_video
	FROM video
	WHERE video.id = NEW.id_video;
		
    IF (durata_interazione > durata_video) THEN
        RAISE EXCEPTION 'Il tempo di visualizzazione deve essere minore o uguale alla durata del video.';
    END IF;

	SELECT skip INTO skip_video
	FROM video
	WHERE video.id = NEW.id_video;

	SELECT click_su_skip INTO skip_interazione
	FROM interazione
	WHERE interazione.id = NEW.id_interazione;

	IF (skip_interazione IS NULL AND skip_video = TRUE) THEN
 	    RAISE EXCEPTION 'Questa interazione deve avere click su skip ';
   	END IF;

  	IF (skip_interazione IS NOT NULL AND skip_video = FALSE) THEN
        RAISE EXCEPTION 'Questa interazione non può avere click su skip ';
    END IF;
	
    RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER verifica_v_i
AFTER INSERT OR UPDATE ON v_i
FOR EACH ROW
EXECUTE FUNCTION verifica_v_i();

-----------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION verifica_update_interazione() RETURNS TRIGGER AS $$
DECLARE
    video_associato INTEGER;

    controllo_data_inizio DATE;
    controllo_data_fine DATE;

    durata_video TIME;	

    skip_video BOOL;

BEGIN
    SELECT id_video INTO video_associato
    FROM v_i
   	WHERE v_i.id_interazione = NEW.id;

    SELECT data_inizio INTO controllo_data_inizio
    FROM campagna
    WHERE campagna.id_video = video_associato;

    SELECT data_fine INTO controllo_data_fine
    FROM campagna
    WHERE campagna.id_video = video_associato;
	
	IF (controllo_data_fine IS NOT NULL) THEN
        RAISE EXCEPTION 'Il video associato all''interazione non appartiene ad una campagna corrente.';
	END IF;
	
	IF (NEW.data_e_ora < controllo_data_inizio) THEN
        RAISE EXCEPTION 'La data dell''interazione deve essere maggiore o uguale alla data di inizio della campagna.';
	END IF;

	SELECT durata INTO durata_video
	FROM video
	WHERE video.id = video_associato;
	
    IF (NEW.tempo_di_visualizzazione > durata_video) THEN
        RAISE EXCEPTION 'Il tempo di visualizzazione deve essere minore o uguale alla durata del video.';
    END IF;

	SELECT skip INTO skip_video
	FROM video
	WHERE video.id = video_associato;
	
	IF (NEW.click_su_skip IS NULL AND skip_video = TRUE) THEN
		RAISE EXCEPTION 'Questa interazione deve avere click su skip';
   	END IF;
	
	IF (NEW.click_su_skip IS NOT NULL AND skip_video = FALSE) THEN
    	RAISE EXCEPTION 'Questa interazione non può avere click su skip ';
    END IF;
	
    RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER verifica_update_interazione
AFTER UPDATE ON interazione
FOR EACH ROW
EXECUTE FUNCTION verifica_update_interazione();

/* 9.2.2. Trigger2: cardinalita_tag */
CREATE OR REPLACE FUNCTION cardinalita_tag() RETURNS TRIGGER AS $$
BEGIN
	IF (EXISTS (SELECT nome
                FROM tag
		        WHERE nome NOT IN (SELECT nome_tag FROM v_t))
    ) THEN RAISE EXCEPTION 'Non è possibile avere un tag che non è associato a nessun video';
	END IF;

	RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER cardinalita_tag
AFTER INSERT ON tag
FOR EACH ROW
EXECUTE FUNCTION cardinalita_tag();

CREATE TRIGGER cardinalita_tag
AFTER DELETE OR UPDATE OF nome_tag ON v_t
FOR EACH ROW
EXECUTE FUNCTION cardinalita_tag();

/* 9.2.3. Trigger3: cardinalita_azienda */
CREATE OR REPLACE FUNCTION cardinalita_azienda() RETURNS TRIGGER AS $$
BEGIN
    IF (EXISTS (SELECT partita_iva
		        FROM azienda
		        WHERE partita_iva NOT IN (SELECT partita_iva FROM campagna))
    ) THEN RAISE EXCEPTION 'Non è possibile avere un’azienda che non è associata a nessuna campagna';
    END IF;
	
	RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER cardinalita_azienda
AFTER INSERT ON azienda
FOR EACH ROW
EXECUTE FUNCTION cardinalita_azienda();

CREATE TRIGGER cardinalita_azienda
AFTER DELETE OR UPDATE OF partita_iva ON campagna
FOR EACH ROW
EXECUTE FUNCTION cardinalita_azienda();

/* 9.2.4.	Trigger4: cardinalita_utente */
CREATE OR REPLACE FUNCTION cardinalita_utente() RETURNS TRIGGER AS $$
BEGIN
    IF (EXISTS (SELECT nickname
                FROM utente
		        WHERE nickname NOT IN (SELECT nickname_utente FROM interazione))
    ) THEN RAISE EXCEPTION 'Non è possibile avere un utente che non è associato a nessuna interazione';
	END IF;
	
	RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER cardinalita_utente
AFTER INSERT ON utente
FOR EACH ROW
EXECUTE FUNCTION cardinalita_utente();

CREATE TRIGGER cardinalita_utente
AFTER DELETE OR UPDATE OF nickname_utente ON interazione
FOR EACH ROW
EXECUTE FUNCTION cardinalita_utente();