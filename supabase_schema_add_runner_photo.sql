-- ============================================
-- เพิ่ม Column สำหรับเก็บรูปภาพนักวิ่ง
-- ============================================
-- Run this in Supabase SQL Editor
-- วันที่: 2026-01-09
-- ============================================

-- เพิ่ม column สำหรับเก็บ URL ของรูปภาพนักวิ่ง
ALTER TABLE runners 
ADD COLUMN IF NOT EXISTS runner_photo_url TEXT;

-- เพิ่ม index สำหรับ query ที่มีรูปภาพ
CREATE INDEX IF NOT EXISTS idx_runners_has_photo ON runners(runner_photo_url) WHERE runner_photo_url IS NOT NULL;

-- เพิ่ม comment
COMMENT ON COLUMN runners.runner_photo_url IS 'URL ของรูปภาพนักวิ่ง (เก็บใน Supabase Storage)';

-- ตรวจสอบว่า column ถูกเพิ่มสำเร็จ
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'runners' 
  AND column_name = 'runner_photo_url';

-- ============================================
-- ✅ เสร็จสิ้น!
-- ============================================
-- ขั้นตอนถัดไป:
-- 1. สร้าง Storage Bucket สำหรับรูปภาพนักวิ่ง (ถ้ายังไม่มี)
-- 2. ตั้งค่า Storage Policies
-- 3. อัปโหลดรูปภาพผ่าน UI
-- ============================================

