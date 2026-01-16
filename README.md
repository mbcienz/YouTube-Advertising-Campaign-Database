# YouTube Advertising Campaign Database

A comprehensive database management system for tracking and analyzing YouTube advertising campaigns, built as an academic project for the Database Systems course at University of Salerno.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Database Schema](#database-schema)
- [Technologies](#technologies)
- [Installation](#installation)
- [Usage](#usage)
- [Key Components](#key-components)
- [Sample Queries](#sample-queries)
- [Team](#team)
- [License](#license)

## 🎯 Overview

This database system enables companies to manage online advertising campaigns on YouTube, with a focus on tracking user-video interactions and measuring campaign effectiveness through Key Performance Indicators (KPIs).

The system handles:
- Multiple companies commissioning advertising campaigns
- Video-based promotional content
- User interactions with sponsored videos
- Technical and economic KPIs for performance analysis
- Campaign lifecycle management (current and concluded campaigns)

## ✨ Features

### Core Functionality

- **Company Management**: Track companies with VAT numbers, contact details, and campaign portfolios
- **Campaign Tracking**: Monitor campaigns with budgets, target demographics, and success metrics
- **Video Analytics**: Store video metadata including URL, duration, resolution, skip functionality, and view counts
- **User Interaction Logging**: Record detailed interaction data including:
  - View timestamp and duration
  - Skip button clicks
  - Video link clicks
  - Likes and shares
- **KPI Monitoring**: Calculate and track performance indicators such as:
  - **Technical KPIs**: Reach, Frequency, Complete View Rate, Skip Rate
  - **Economic KPIs**: Cost per Click, Cost per Like, Cost per Share

### Advanced Features

- **Automatic View Count Maintenance**: Triggers ensure view counts stay synchronized with interaction records
- **Campaign State Management**: Distinguish between active and concluded campaigns
- **Business Rule Enforcement**: Database triggers validate:
  - Interaction timestamps against campaign dates
  - View duration against video length
  - Skip interactions based on video type
  - Minimum cardinality constraints
- **Comprehensive Views**: Pre-built views for video summaries and campaign monitoring
- **Data Integrity**: Full normalization to BCNF (Boyce-Codd Normal Form)

## 🗄️ Database Schema

### Main Entities

- **AZIENDA** (Company): VAT, name, legal address, contact info
- **CAMPAGNA** (Campaign): ID, name, dates, budget, target demographics, success metrics
- **VIDEO**: ID, URL, title, description, duration, resolution, view count, skip availability
- **UTENTE** (User): Nickname, email, personal info, demographics
- **INTERAZIONE** (Interaction): ID, timestamp, view duration, engagement metrics
- **KPI**: Name, calculation formula, description, type (technical/economic)
- **TAG**: Video categorization tags
- **MONITORAGGIO** (Monitoring): Links KPIs to videos with calculated values

### Key Relationships

- Companies commission campaigns (1:N)
- Campaigns promote videos (1:1)
- Videos have multiple interactions (1:N)
- Users create multiple interactions (1:N)
- Videos are monitored by multiple KPIs (N:M)
- Videos have multiple tags (N:M)

## 🛠️ Technologies

- **Database**: PostgreSQL
- **Language**: SQL (PL/pgSQL for triggers and functions)
- **Design Methodology**: 
  - ER modeling with design patterns (Reification, Part-of, Historicization)
  - Mixed strategy approach (top-down and bottom-up)
  - Full normalization analysis

## 📥 Installation

### Prerequisites

- PostgreSQL 12 or higher
- psql command-line tool or pgAdmin

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd youtube-ad-campaign-db
   ```

2. **Create the database**
   ```bash
   psql -U postgres -f script_creazione.sql
   ```

3. **Populate with sample data**
   ```bash
   psql -U postgres -d basi_di_dati_gruppo_05 -f script_popolamento.sql
   ```

4. **Verify installation**
   ```bash
   psql -U postgres -d basi_di_dati_gruppo_05
   \dt  # List all tables
   ```

## 💻 Usage

### Inserting a New Interaction

```sql
BEGIN TRANSACTION;

-- Insert interaction
INSERT INTO interazione(id, data_e_ora, tempo_di_visualizzazione, 
                       click_su_skip, click_su_video, "like", 
                       condivisione, nickname_utente) 
VALUES (19, '2023-06-15 14:30:00', '00:01:30', FALSE, TRUE, TRUE, 
        FALSE, 'enzosong');

-- Link interaction to video
INSERT INTO v_i(id_interazione, id_video) VALUES (19, 1);

COMMIT;
```

### Updating KPIs

KPI values are stored in the `monitoraggio` table and updated based on interaction data:

```sql
UPDATE monitoraggio 
SET valore = (
    SELECT COUNT(DISTINCT nickname_utente)
    FROM interazione i
    JOIN v_i ON i.id = v_i.id_interazione
    WHERE v_i.id_video = 1
)
WHERE nome_kpi = 'Reach' AND id_video = 1;
```

### Querying Campaign Performance

```sql
-- Top 3 most successful companies
SELECT A.nome AS nome_azienda, 
       AVG(C.raggiungimento_obiettivo) AS raggiungimento_obiettivo_medio
FROM azienda AS A
JOIN campagna AS C ON A.partita_iva = C.partita_iva
WHERE C.raggiungimento_obiettivo IS NOT NULL
GROUP BY nome_azienda
ORDER BY raggiungimento_obiettivo_medio DESC
LIMIT 3;
```

## 🔑 Key Components

### Database Triggers

1. **v_i & proteggi_numero_visualizzazioni**: Maintains view count redundancy
2. **verifica_v_i & verifica_update_interazione**: Enforces business rules on interactions
3. **cardinalita_tag**: Ensures tags are associated with videos
4. **cardinalita_azienda**: Ensures companies have campaigns
5. **cardinalita_utente**: Ensures users have interactions

### Views

1. **riepilogo_video**: Comprehensive video summary with aggregated metrics
   - Total likes, shares, skips, clicks
   - Average view duration
   - Total view count

2. **monitoraggio_campagne**: Campaign monitoring dashboard
   - Campaign details with associated videos
   - KPI values for performance tracking

### Design Patterns Used

- **Reification**: Converted User-Video relationship to Interaction entity
- **Part-of**: Campaign as part of Company structure
- **Historicization**: Separated current and concluded campaigns

## 📊 Sample Queries

### Videos with Above-Average Views

```sql
SELECT *
FROM riepilogo_video
WHERE numero_visualizzazioni > (
    SELECT AVG(numero_visualizzazioni)
    FROM riepilogo_video
)
ORDER BY tempo_medio_visualizzazione DESC;
```

### Music Videos with 3+ Views

```sql
SELECT V.titolo, V.numero_visualizzazioni
FROM video AS V
JOIN v_t ON V.id = v_t.id_video
WHERE v_t.nome_tag = 'musica'
INTERSECT
SELECT V.titolo, V.numero_visualizzazioni
FROM video AS V
WHERE V.numero_visualizzazioni >= 3;
```

### Cost per Reach Analysis

```sql
SELECT id_campagna, nome_campagna, titolo_video, url_video, 
       (budget/valore_kpi) AS costo_per_reach
FROM monitoraggio_campagne
WHERE nome_kpi = 'Reach' AND data_fine IS NOT NULL
ORDER BY costo_per_reach;
```

### Companies Associated with Top 3 Most Active Users

```sql
SELECT azienda.nome AS nome_azienda, 
       utenti_interazioni.utente, 
       COUNT(interazione.nickname_utente) AS numero_interazioni
FROM (
    SELECT interazione.nickname_utente as utente, 
           COUNT(*) AS num_interazioni
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
ORDER BY numero_interazioni DESC, utenti_interazioni.utente;
```

## 📚 Documentation

For detailed documentation including:
- Complete ER diagrams
- Normalization analysis (1NF through BCNF)
- Functional dependencies
- Business rules and constraints
- Performance analysis

Please refer to the original project report: `Relazione Project Work Basi di Dati 2022-2023 A-H.pdf`
