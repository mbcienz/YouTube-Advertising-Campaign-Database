/* 7.1.	Query con operatore di aggregazione e join: Azienda-visualizzazioni_totali-tempo_medio_di_visualizzazione */
SELECT A.nome, COUNT(I.id) AS visualizzazioni_totali, AVG (I.tempo_di_visualizzazione) AS tempo_medio_di_visualizzazione
FROM azienda AS A
JOIN campagna AS C ON A.partita_iva = C.partita_iva
JOIN video AS V ON C.id_video = V.id
JOIN v_i ON v_i.id_video = V.id 
JOIN interazione AS I ON I.id = v_i.id_interazione
GROUP BY A.nome
ORDER BY visualizzazioni_totali DESC

/* 7.2.	Query nidificata complessa: aziende associate ai tre utenti con più interazioni */
SELECT azienda.nome AS nome_azienda, utenti_interazioni.utente, COUNT(interazione.nickname_utente) AS numero_interazioni
FROM (
    SELECT interazione.nickname_utente as utente, COUNT(*) AS num_interazioni
    FROM interazione
    GROUP BY interazione.nickname_utente
    ORDER BY num_interazioni DESC
    LIMIT 3
) AS utenti_interazioni
JOIN interazione ON interazione.nickname_utente = utenti_interazioni.utente
JOIN v_i ON interazione.id = v_i.id_interazione
JOIN video ON video.id = v_i.id_video
JOIN campagna ON campagna.id = video.id_campagna
JOIN azienda ON azienda.partita_iva = campagna.partita_iva
GROUP BY azienda.nome, utenti_interazioni.utente
ORDER BY numero_interazioni DESC, utenti_interazioni.utente

/* 7.3.	Query insiemistica: Video musicali con almeno 3 visualizzazioni */
SELECT V.titolo, V.numero_visualizzazioni
FROM video AS V
JOIN v_t ON V.id = v_t.id_video
WHERE v_t.nome_tag = 'musica'
INTERSECT
SELECT V.titolo, V.numero_visualizzazioni
FROM video AS V
WHERE v.numero_visualizzazioni >= 3

/* 7.4.	Altre query*/
/* 7.4.1. Operazione 7: tre aziende con maggior successo */
SELECT A.nome AS nome_azienda, AVG(C.raggiungimento_obiettivo) AS raggiungimento_obiettivo_medio
FROM azienda AS A
JOIN campagna AS C ON A.partita_iva = C.partita_iva
WHERE C.raggiungimento_obiettivo IS NOT NULL
GROUP BY nome_azienda
ORDER BY raggiungimento_obiettivo_medio DESC
LIMIT 3

/* 8.1.	Vista riepilogo_video */
CREATE VIEW riepilogo_video AS
SELECT V.id, V.url, V.titolo, V.numero_visualizzazioni,
    	COALESCE(likes.numero_like, 0) AS numero_like,
    	COALESCE(condivisioni.numero_condivisioni, 0) AS numero_condivisioni,
    	COALESCE(skip.numero_skip, 0) AS numero_skip,
    	COALESCE(click.numero_click, 0) AS numero_click,
        COALESCE(tempo_medio_visualizzazione.media_tempo_visualizzazione, '00:00:00') AS tempo_medio_visualizzazione	

FROM video V
LEFT JOIN (SELECT count(*) AS numero_like, v_i.id_video AS id_video
FROM interazione I
JOIN v_i ON v_i.id_interazione = I.id
WHERE I.like = true
GROUP BY v_i.id_video
) AS likes ON likes.id_video = V.id
		   
LEFT JOIN (SELECT count(*) AS numero_condivisioni, v_i.id_video AS id_video
FROM interazione I
JOIN v_i ON v_i.id_interazione = I.id
WHERE I.condivisione = true
GROUP BY v_i.id_video
	) AS condivisioni ON condivisioni.id_video = V.id
		  
LEFT JOIN (SELECT count(*) AS numero_skip, v_i.id_video AS id_video
FROM interazione I
JOIN v_i ON v_i.id_interazione = I.id
WHERE I.click_su_skip = true
GROUP BY v_i.id_video
	) AS skip ON skip.id_video = V.id
		  
LEFT JOIN (SELECT count(*) AS numero_click, v_i.id_video AS id_video
FROM interazione I
JOIN v_i ON v_i.id_interazione = I.id
WHERE I.click_su_video = true
GROUP BY v_i.id_video
	) AS click ON click.id_video = V.id
		  
LEFT JOIN (SELECT AVG(I.tempo_di_visualizzazione) AS media_tempo_visualizzazione, v_i.id_video AS id_video
FROM interazione I
JOIN v_i ON v_i.id_interazione = I.id
GROUP BY v_i.id_video
	) AS tempo_medio_visualizzazione ON tempo_medio_visualizzazione.id_video = V.id
		  
ORDER BY V.id;

/* 8.1.1.	Query con Vista: video con numero di visualizzazioni maggiore della media */
SELECT *
FROM riepilogo_video
WHERE numero_visualizzazioni > (
    SELECT AVG(numero_visualizzazioni)
    FROM riepilogo_video
)
ORDER BY tempo_medio_visualizzazione DESC


/* 8.2.	Vista monitoraggio_campagne */
CREATE VIEW monitoraggio_campagne AS
SELECT C.id AS id_campagna, C.nome AS nome_campagna, C.data_inizio, C.data_fine, C.budget,
       V.id AS id_video, V.url AS url_video, V.titolo AS titolo_video,
       K.nome AS nome_kpi, M.valore AS valore_kpi
FROM campagna AS C
JOIN video AS V ON C.id_video = V.id
JOIN monitoraggio AS M ON V.id = M.id_video
JOIN kpi K ON M.nome_kpi = K.nome
ORDER BY C.id

/* 8.2.1.	Query con Vista: Costo per reach */
SELECT id_campagna, nome_campagna, titolo_video, url_video, (budget/valore_kpi) AS costo_per_reach
FROM monitoraggio_campagne
WHERE nome_kpi = 'Reach' AND data_fine IS NOT NULL
ORDER BY costo_per_reach