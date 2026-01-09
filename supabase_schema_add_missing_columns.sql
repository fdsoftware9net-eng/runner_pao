-- ============================================
-- เพิ่ม Columns ที่ขาดหายไปใน runners table
-- ============================================
-- Run this in Supabase SQL Editor
-- วันที่: 2026-01-09
-- ============================================

-- เพิ่ม columns ที่ขาดหายไป
ALTER TABLE runners 
ADD COLUMN IF NOT EXISTS name_on_bib TEXT,
ADD COLUMN IF NOT EXISTS race_kit TEXT,
ADD COLUMN IF NOT EXISTS row TEXT,
ADD COLUMN IF NOT EXISTS row_no TEXT,
ADD COLUMN IF NOT EXISTS row_start TEXT,
ADD COLUMN IF NOT EXISTS shirt TEXT,
ADD COLUMN IF NOT EXISTS shirt_type TEXT,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS nationality TEXT,
ADD COLUMN IF NOT EXISTS age_category TEXT,
ADD COLUMN IF NOT EXISTS block TEXT,
ADD COLUMN IF NOT EXISTS wave_start TEXT,
ADD COLUMN IF NOT EXISTS pre_order TEXT,
ADD COLUMN IF NOT EXISTS first_half_marathon TEXT,
ADD COLUMN IF NOT EXISTS note TEXT,
ADD COLUMN IF NOT EXISTS top_50_no TEXT,
ADD COLUMN IF NOT EXISTS pass_generated BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS google_jwt TEXT,
ADD COLUMN IF NOT EXISTS apple_pass_url TEXT;

-- เพิ่ม indexes สำหรับ columns ที่ใช้บ่อย
CREATE INDEX IF NOT EXISTS idx_runners_gender ON runners(gender) WHERE gender IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_age_category ON runners(age_category) WHERE age_category IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_wave_start ON runners(wave_start) WHERE wave_start IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_runners_pass_generated ON runners(pass_generated);

-- เพิ่ม comments
COMMENT ON COLUMN runners.name_on_bib IS 'ชื่อที่แสดงบน BIB (optional)';
COMMENT ON COLUMN runners.race_kit IS 'ประเภท Race Kit';
COMMENT ON COLUMN runners.row IS 'แถว';
COMMENT ON COLUMN runners.row_no IS 'เลขที่แถว';
COMMENT ON COLUMN runners.shirt IS 'ขนาด Shirt';
COMMENT ON COLUMN runners.shirt_type IS 'ประเภท Shirt';
COMMENT ON COLUMN runners.gender IS 'เพศ';
COMMENT ON COLUMN runners.nationality IS 'สัญชาติ';
COMMENT ON COLUMN runners.age_category IS 'หมวดอายุ';
COMMENT ON COLUMN runners.block IS 'บล็อก';
COMMENT ON COLUMN runners.wave_start IS 'รอบการวิ่ง';
COMMENT ON COLUMN runners.pre_order IS 'Pre Order';
COMMENT ON COLUMN runners.first_half_marathon IS 'ครั้งแรกที่วิ่งฮาล์ฟมาราธอน';
COMMENT ON COLUMN runners.note IS 'หมายเหตุ';
COMMENT ON COLUMN runners.top_50_no IS 'เลขที่ TOP 50';
COMMENT ON COLUMN runners.pass_generated IS 'สถานะการสร้าง pass';
COMMENT ON COLUMN runners.google_jwt IS 'Google Wallet JWT token';
COMMENT ON COLUMN runners.apple_pass_url IS 'Apple Wallet pass URL';

-- ตรวจสอบว่า columns ถูกเพิ่มสำเร็จ
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'runners' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- ============================================
-- ✅ เสร็จสิ้น!
-- ============================================

