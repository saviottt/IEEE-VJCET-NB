-- IEEE Event Keeper: Collaborative Public Calendar Schema

-- 1. Create Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Events Table (Removed user_id for public access)
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    venue TEXT NOT NULL,
    organizer_name TEXT NOT NULL,
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime TIMESTAMPTZ NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    banner_url TEXT,
    registration_link TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- 4. Create Public Policies (Full CRUD for everyone)
-- Category Policies
CREATE POLICY "Allow public read access to categories" ON categories
    FOR SELECT USING (true);

-- Event Policies
CREATE POLICY "Allow public read access to events" ON events
    FOR SELECT USING (true);

CREATE POLICY "Allow public insert access to events" ON events
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public update access to events" ON events
    FOR UPDATE USING (true);

CREATE POLICY "Allow public delete access to events" ON events
    FOR DELETE USING (true);

-- 5. Insert Initial Categories
INSERT INTO categories (name, color) VALUES
('Workshops', '#2196F3'),
('Conferences', '#9C27B0'),
('Seminars', '#4CAF50'),
('Networking', '#FF9800'),
('Competitions', '#F44336'),
('Other', '#607D8B')
ON CONFLICT DO NOTHING;
