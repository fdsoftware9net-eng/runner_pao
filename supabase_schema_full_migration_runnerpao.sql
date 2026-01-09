-- ============================================
-- Full Database Schema Migration Script
-- สำหรับ Supabase Project: runnerpao
-- ============================================
-- ไฟล์นี้รวม schema ทั้งหมดเข้าด้วยกัน สามารถรันครั้งเดียวเสร็จทั้งหมด
-- เรียงลำดับตาม dependencies เพื่อให้แน่ใจว่าทุกอย่างถูกสร้างอย่างถูกต้อง
--
-- สร้างโดย: Project-Fang Team
-- วันที่: 2026-01-09
-- ============================================

-- ============================================
-- STEP 1: สร้าง TABLES หลัก
-- ============================================

-- ============================================
-- Table: runners
-- ============================================
-- เก็บข้อมูล runners ทั้งหมด

CREATE TABLE IF NOT EXISTS runners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Runner Information
    bib TEXT NOT NULL UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    name_on_bib TEXT,
    email TEXT,
    phone TEXT,
    
    -- ID Card (hashed for privacy)
    id_card_hash TEXT,
    
    -- Access Key for secure lookup
    access_key TEXT UNIQUE,
    
    -- Race Kit & Registration Info
    race_kit TEXT,
    row TEXT,
    row_no TEXT,
    row_start TEXT,
    shirt TEXT,
    shirt_type TEXT,
    gender TEXT,
    nationality TEXT,
    age_category TEXT,
    block TEXT,
    wave_start TEXT,
    pre_order TEXT,
    first_half_marathon TEXT,
    note TEXT,
    top_50_no TEXT,
    
    -- Race Information
    race_category TEXT,
    race_distance TEXT,
    start_time TIMESTAMP WITH TIME ZONE,
    
    -- Result Information
    finish_time TIMESTAMP WITH TIME ZONE,
    gun_time TEXT,
    chip_time TEXT,
    pace TEXT,
    rank_overall INTEGER,
    rank_category INTEGER,
    rank_gender INTEGER,
    
    -- Pass Information
    pass_generated BOOLEAN DEFAULT false,
    pass_url TEXT,
    google_jwt TEXT,
    google_wallet_pass_id TEXT,
    apple_pass_url TEXT,
    
    -- Template Assignment
    web_pass_template_id TEXT,
    
    -- Additional Fields (v3)
    top50 TEXT,
    colour_sign TEXT,
    qr TEXT,
    runner_photo_url TEXT,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for runners table
CREATE INDEX IF NOT EXISTS idx_runners_bib ON runners(bib);
CREATE INDEX IF NOT EXISTS idx_runners_access_key ON runners(access_key) WHERE access_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_id_card_hash ON runners(id_card_hash) WHERE id_card_hash IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_email ON runners(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_created_at ON runners(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_runners_updated_at ON runners(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_runners_gender ON runners(gender) WHERE gender IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_age_category ON runners(age_category) WHERE age_category IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_wave_start ON runners(wave_start) WHERE wave_start IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_pass_generated ON runners(pass_generated);
CREATE INDEX IF NOT EXISTS idx_runners_has_photo ON runners(runner_photo_url) WHERE runner_photo_url IS NOT NULL;

-- Add comments
COMMENT ON TABLE runners IS 'เก็บข้อมูล runners ทั้งหมด รวมถึงข้อมูลส่วนตัว ผลการแข่งขัน และ pass information';
COMMENT ON COLUMN runners.id_card_hash IS 'SHA-256 hash ของเลขบัตรประชาชน เพื่อความปลอดภัย';
COMMENT ON COLUMN runners.access_key IS 'Key สำหรับเข้าถึงข้อมูล runner (used for secure lookup)';

-- ============================================
-- Table: wallet_config
-- ============================================
-- เก็บ configuration สำหรับ Wallet Passes

CREATE TABLE IF NOT EXISTS wallet_config (
    id INTEGER PRIMARY KEY DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Event Information
    event_name TEXT NOT NULL DEFAULT 'Running Event',
    event_date TEXT,
    event_location TEXT,
    
    -- Organizer Information
    organizer_name TEXT,
    organizer_email TEXT,
    organizer_phone TEXT,
    
    -- Apple Wallet Configuration
    apple_pass_type_id TEXT,
    apple_team_id TEXT,
    
    -- Google Wallet Configuration
    issuer_id TEXT,
    issuer_name TEXT,
    
    -- Pass Design (URLs to images in Storage)
    logo_url TEXT,
    icon_url TEXT,
    background_url TEXT,
    strip_url TEXT,
    thumbnail_url TEXT,
    
    -- Colors (Hex format)
    background_color TEXT DEFAULT '#1a1a1a',
    foreground_color TEXT DEFAULT '#ffffff',
    label_color TEXT DEFAULT '#999999',
    
    -- Web Pass Templates (JSONB array)
    web_pass_templates JSONB DEFAULT '[]'::jsonb,
    
    -- Template Assignment Rules (v2)
    template_assignment_rules JSONB DEFAULT '[]'::jsonb,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Enforce single row
    CONSTRAINT single_row_check CHECK (id = 1)
);

-- Insert default row if not exists
INSERT INTO wallet_config (id) 
VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- Add comments
COMMENT ON TABLE wallet_config IS 'เก็บ configuration สำหรับ Apple Wallet และ Google Wallet passes';
COMMENT ON COLUMN wallet_config.web_pass_templates IS 'Array ของ pass templates สำหรับ Web Pass';
COMMENT ON COLUMN wallet_config.template_assignment_rules IS 'Rules สำหรับการ assign templates อัตโนมัติ';

-- ============================================
-- Table: user_activity_logs (v4)
-- ============================================
-- เก็บ logs สำหรับ tracking user activities

CREATE TABLE IF NOT EXISTS user_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Activity type: 'lookup', 'save_image', 'add_google_wallet', 'add_apple_wallet', 'view_pass', 'update_runner', 'link_line_account'
    activity_type TEXT NOT NULL,
    
    -- Runner ID (nullable for failed lookups)
    runner_id UUID REFERENCES runners(id) ON DELETE SET NULL,
    
    -- Search-related fields (nullable, only for 'lookup' activity)
    search_method TEXT CHECK (search_method IN ('name', 'id_card', 'bib') OR search_method IS NULL),
    search_input_hash TEXT, -- SHA-256 hash of search input for privacy
    
    -- Result of the activity
    success BOOLEAN NOT NULL DEFAULT false,
    
    -- Optional: IP address and user agent for analytics
    ip_address INET,
    user_agent TEXT,
    
    -- Error message if activity failed (nullable)
    error_message TEXT,
    
    -- Metadata for additional information (JSONB for flexibility)
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Add CHECK constraint สำหรับ activity_type (รวม v7 และ v9)
ALTER TABLE user_activity_logs
DROP CONSTRAINT IF EXISTS user_activity_logs_activity_type_check;

ALTER TABLE user_activity_logs
ADD CONSTRAINT user_activity_logs_activity_type_check
CHECK (activity_type IN (
  'lookup',
  'save_image',
  'add_google_wallet',
  'add_apple_wallet',
  'view_pass',
  'update_runner',
  'link_line_account'
));

-- Create indexes for user_activity_logs
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_created_at ON user_activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_activity_type ON user_activity_logs(activity_type);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_runner_id ON user_activity_logs(runner_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_success ON user_activity_logs(success);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_search_method ON user_activity_logs(search_method) WHERE search_method IS NOT NULL;

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_runner_activity ON user_activity_logs(runner_id, activity_type, created_at DESC) WHERE runner_id IS NOT NULL;

-- Add comments
COMMENT ON TABLE user_activity_logs IS 'Logs สำหรับ tracking user activities ทั้งหมด';
COMMENT ON COLUMN user_activity_logs.search_input_hash IS 'SHA-256 hash ของ search input เพื่อความปลอดภัย';
COMMENT ON COLUMN user_activity_logs.metadata IS 'JSONB field สำหรับเก็บข้อมูลเพิ่มเติมที่เฉพาะเจาะจง';

-- ============================================
-- STEP 2: Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS for runners table
ALTER TABLE runners ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public to SELECT runners (for public lookup)
CREATE POLICY "Allow public select on runners"
ON runners
FOR SELECT
TO anon, authenticated
USING (true);

-- Policy: Allow authenticated users to INSERT runners (admin only)
CREATE POLICY "Allow authenticated insert on runners"
ON runners
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Allow authenticated users to UPDATE runners (admin only)
CREATE POLICY "Allow authenticated update on runners"
ON runners
FOR UPDATE
TO authenticated
USING (true);

-- Enable RLS for wallet_config table
ALTER TABLE wallet_config ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public to SELECT wallet_config
CREATE POLICY "Allow public select on wallet_config"
ON wallet_config
FOR SELECT
TO anon, authenticated
USING (true);

-- Policy: Allow authenticated users to UPDATE wallet_config
CREATE POLICY "Allow authenticated update on wallet_config"
ON wallet_config
FOR UPDATE
TO authenticated
USING (true);

-- Enable RLS for user_activity_logs table
ALTER TABLE user_activity_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anonymous users to INSERT logs
CREATE POLICY "Allow anonymous insert on user_activity_logs"
ON user_activity_logs
FOR INSERT
TO anon
WITH CHECK (true);

-- Policy: Allow authenticated users to INSERT logs
CREATE POLICY "Allow authenticated insert on user_activity_logs"
ON user_activity_logs
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Allow authenticated users to SELECT logs (admin can view)
CREATE POLICY "Allow authenticated select on user_activity_logs"
ON user_activity_logs
FOR SELECT
TO authenticated
USING (true);

-- ============================================
-- STEP 3: RPC Functions
-- ============================================

-- ============================================
-- Function: log_user_activity (v8)
-- ============================================
-- RPC function สำหรับ logging user activity (bypass RLS)

CREATE OR REPLACE FUNCTION log_user_activity(
    p_activity_type TEXT,
    p_runner_id UUID DEFAULT NULL,
    p_search_method TEXT DEFAULT NULL,
    p_search_input_hash TEXT DEFAULT NULL,
    p_success BOOLEAN DEFAULT false,
    p_error_message TEXT DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO user_activity_logs (
        activity_type,
        runner_id,
        search_method,
        search_input_hash,
        success,
        error_message,
        user_agent,
        ip_address,
        metadata
    ) VALUES (
        p_activity_type,
        p_runner_id,
        p_search_method,
        p_search_input_hash,
        p_success,
        p_error_message,
        p_user_agent,
        p_ip_address,
        p_metadata
    )
    RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$;

GRANT EXECUTE ON FUNCTION log_user_activity TO public;
GRANT EXECUTE ON FUNCTION log_user_activity TO authenticated;

COMMENT ON FUNCTION log_user_activity IS 'Log user activity โดย bypass RLS ด้วย SECURITY DEFINER';

-- ============================================
-- Function: get_activity_statistics (v10 - includes LINE Account)
-- ============================================
-- ดึงสถิติการใช้งานรวม

DROP FUNCTION IF EXISTS get_activity_statistics(INTEGER);

CREATE OR REPLACE FUNCTION get_activity_statistics(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    total_lookups BIGINT,
    successful_lookups BIGINT,
    failed_lookups BIGINT,
    lookup_success_rate NUMERIC,
    total_downloads BIGINT,
    successful_downloads BIGINT,
    failed_downloads BIGINT,
    download_success_rate NUMERIC,
    total_google_wallet BIGINT,
    successful_google_wallet BIGINT,
    failed_google_wallet BIGINT,
    google_wallet_success_rate NUMERIC,
    total_apple_wallet BIGINT,
    successful_apple_wallet BIGINT,
    failed_apple_wallet BIGINT,
    apple_wallet_success_rate NUMERIC,
    total_link_line_account BIGINT,
    successful_link_line_account BIGINT,
    failed_link_line_account BIGINT,
    link_line_account_success_rate NUMERIC
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    start_date TIMESTAMP WITH TIME ZONE;
BEGIN
    start_date := NOW() - (days_back || ' days')::INTERVAL;
    
    RETURN QUERY
    SELECT 
        -- Lookup Statistics
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'lookup' AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'lookup' AND success = true AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'lookup' AND success = false AND created_at >= start_date),
        CASE 
            WHEN (SELECT COUNT(*) FROM user_activity_logs WHERE activity_type = 'lookup' AND created_at >= start_date) > 0
            THEN ROUND((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'lookup' AND success = true AND created_at >= start_date) / NULLIF((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'lookup' AND created_at >= start_date), 0) * 100, 2)
            ELSE 0
        END,
        
        -- Download Statistics
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'save_image' AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'save_image' AND success = true AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'save_image' AND success = false AND created_at >= start_date),
        CASE 
            WHEN (SELECT COUNT(*) FROM user_activity_logs WHERE activity_type = 'save_image' AND created_at >= start_date) > 0
            THEN ROUND((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'save_image' AND success = true AND created_at >= start_date) / NULLIF((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'save_image' AND created_at >= start_date), 0) * 100, 2)
            ELSE 0
        END,
        
        -- Google Wallet Statistics
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'add_google_wallet' AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'add_google_wallet' AND success = true AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'add_google_wallet' AND success = false AND created_at >= start_date),
        CASE 
            WHEN (SELECT COUNT(*) FROM user_activity_logs WHERE activity_type = 'add_google_wallet' AND created_at >= start_date) > 0
            THEN ROUND((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'add_google_wallet' AND success = true AND created_at >= start_date) / NULLIF((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'add_google_wallet' AND created_at >= start_date), 0) * 100, 2)
            ELSE 0
        END,
        
        -- Apple Wallet Statistics
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'add_apple_wallet' AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'add_apple_wallet' AND success = true AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'add_apple_wallet' AND success = false AND created_at >= start_date),
        CASE 
            WHEN (SELECT COUNT(*) FROM user_activity_logs WHERE activity_type = 'add_apple_wallet' AND created_at >= start_date) > 0
            THEN ROUND((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'add_apple_wallet' AND success = true AND created_at >= start_date) / NULLIF((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'add_apple_wallet' AND created_at >= start_date), 0) * 100, 2)
            ELSE 0
        END,
        
        -- LINE Account Statistics
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'link_line_account' AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'link_line_account' AND success = true AND created_at >= start_date),
        (SELECT COUNT(*)::BIGINT FROM user_activity_logs WHERE activity_type = 'link_line_account' AND success = false AND created_at >= start_date),
        CASE 
            WHEN (SELECT COUNT(*) FROM user_activity_logs WHERE activity_type = 'link_line_account' AND created_at >= start_date) > 0
            THEN ROUND((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'link_line_account' AND success = true AND created_at >= start_date) / NULLIF((SELECT COUNT(*)::NUMERIC FROM user_activity_logs WHERE activity_type = 'link_line_account' AND created_at >= start_date), 0) * 100, 2)
            ELSE 0
        END;
END;
$$;

GRANT EXECUTE ON FUNCTION get_activity_statistics(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_activity_statistics(INTEGER) TO anon;

COMMENT ON FUNCTION get_activity_statistics(INTEGER) IS 'ดึงสถิติการใช้งานรวมทั้งหมด (lookups, downloads, wallets, LINE Account)';

-- ============================================
-- Function: get_daily_statistics (v10 - includes LINE Account)
-- ============================================
-- ดึงสถิติรายวัน

DROP FUNCTION IF EXISTS get_daily_statistics(INTEGER);

CREATE OR REPLACE FUNCTION get_daily_statistics(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    date DATE,
    lookups BIGINT,
    downloads BIGINT,
    google_wallet BIGINT,
    apple_wallet BIGINT,
    link_line_account BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    start_date TIMESTAMP WITH TIME ZONE;
BEGIN
    start_date := NOW() - (days_back || ' days')::INTERVAL;
    
    RETURN QUERY
    SELECT 
        DATE(ual.created_at) as date,
        COUNT(*) FILTER (WHERE ual.activity_type = 'lookup')::BIGINT as lookups,
        COUNT(*) FILTER (WHERE ual.activity_type = 'save_image')::BIGINT as downloads,
        COUNT(*) FILTER (WHERE ual.activity_type = 'add_google_wallet')::BIGINT as google_wallet,
        COUNT(*) FILTER (WHERE ual.activity_type = 'add_apple_wallet')::BIGINT as apple_wallet,
        COUNT(*) FILTER (WHERE ual.activity_type = 'link_line_account')::BIGINT as link_line_account
    FROM user_activity_logs ual
    WHERE ual.activity_type IN ('lookup', 'save_image', 'add_google_wallet', 'add_apple_wallet', 'link_line_account')
        AND ual.created_at >= start_date
    GROUP BY DATE(ual.created_at)
    ORDER BY date DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_daily_statistics(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_daily_statistics(INTEGER) TO anon;

COMMENT ON FUNCTION get_daily_statistics(INTEGER) IS 'ดึงสถิติรายวัน แยกตาม activity type';

-- ============================================
-- Function: get_runner_updates (v6)
-- ============================================
-- ดึงรายการ runners ที่ถูก update

CREATE OR REPLACE FUNCTION get_runner_updates(
  days_back INTEGER DEFAULT 30,
  limit_count INTEGER DEFAULT 100
)
RETURNS TABLE (
  runner_id UUID,
  runner_bib TEXT,
  runner_name TEXT,
  update_count BIGINT,
  last_updated_at TIMESTAMP WITH TIME ZONE,
  success_count BIGINT,
  failed_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  start_date TIMESTAMP WITH TIME ZONE;
BEGIN
  start_date := NOW() - (days_back || ' days')::INTERVAL;
  
  RETURN QUERY
  SELECT 
    ual.runner_id,
    r.bib as runner_bib,
    CONCAT(r.first_name, ' ', r.last_name) as runner_name,
    COUNT(*)::BIGINT as update_count,
    MAX(ual.created_at) as last_updated_at,
    COUNT(*) FILTER (WHERE ual.success = true)::BIGINT as success_count,
    COUNT(*) FILTER (WHERE ual.success = false)::BIGINT as failed_count
  FROM user_activity_logs ual
  LEFT JOIN runners r ON r.id = ual.runner_id
  WHERE ual.activity_type = 'update_runner'
    AND ual.created_at >= start_date
    AND ual.runner_id IS NOT NULL
  GROUP BY ual.runner_id, r.bib, r.first_name, r.last_name
  ORDER BY last_updated_at DESC
  LIMIT limit_count;
END;
$$;

GRANT EXECUTE ON FUNCTION get_runner_updates(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_runner_updates(INTEGER, INTEGER) TO anon;

COMMENT ON FUNCTION get_runner_updates(INTEGER, INTEGER) IS 'ดึงรายการ runners ที่ถูก update พร้อมสถิติ';

-- ============================================
-- STEP 4: Triggers สำหรับ updated_at
-- ============================================

-- Function สำหรับ update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger สำหรับ runners table
DROP TRIGGER IF EXISTS update_runners_updated_at ON runners;
CREATE TRIGGER update_runners_updated_at
    BEFORE UPDATE ON runners
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger สำหรับ wallet_config table
DROP TRIGGER IF EXISTS update_wallet_config_updated_at ON wallet_config;
CREATE TRIGGER update_wallet_config_updated_at
    BEFORE UPDATE ON wallet_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 5: Verification Queries
-- ============================================

-- ตรวจสอบ Tables ที่ถูกสร้าง
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;

-- ตรวจสอบ RPC Functions ที่ถูกสร้าง
-- SELECT routine_name, routine_type FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION' ORDER BY routine_name;

-- ตรวจสอบ RLS Policies
-- SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;

-- ============================================
-- END OF MIGRATION SCRIPT
-- ============================================
-- ✅ Schema migration เสร็จสมบูรณ์!
-- ✅ ต่อไป: สร้าง Storage Bucket และ Deploy Edge Functions
-- ============================================

