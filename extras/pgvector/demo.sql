-- A 3-dimensional toy version of what P1 does with 1,024-dimensional embeddings.
-- Run it with:  docker compose exec -T db psql -U postgres -d rag < demo.sql

CREATE EXTENSION IF NOT EXISTS vector;
SELECT extversion AS pgvector_version FROM pg_extension WHERE extname = 'vector';

DROP TABLE IF EXISTS items;
CREATE TABLE items (
    id        bigserial PRIMARY KEY,
    label     text NOT NULL,
    embedding vector(3) NOT NULL
);

INSERT INTO items (label, embedding) VALUES
    ('cat',    '[1, 0, 0]'),
    ('kitten', '[0.9, 0.1, 0]'),
    ('car',    '[0, 0, 1]');

-- <-> is Euclidean (L2) distance: smaller means closer.
SELECT label, round((embedding <-> '[1, 0, 0]')::numeric, 3) AS l2_distance
FROM items
ORDER BY embedding <-> '[1, 0, 0]';

-- <=> is cosine distance (1 - cosine similarity). Most text embeddings use it.
SELECT label, round((1 - (embedding <=> '[1, 0, 0]'))::numeric, 3) AS cosine_similarity
FROM items
ORDER BY embedding <=> '[1, 0, 0]';
