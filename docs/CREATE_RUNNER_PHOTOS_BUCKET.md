# 📦 คู่มือ: สร้าง Storage Bucket สำหรับรูปภาพนักวิ่ง

คู่มือสร้าง Storage Bucket ชื่อ `runner_photos` แบบละเอียดทีละขั้นตอน

---

## 🎯 ภาพรวม

Storage Bucket จะเป็นที่เก็บไฟล์รูปภาพนักวิ่งทั้งหมด โดย:
- **Public Access:** ทุกคนสามารถดูรูปได้ (แต่ไม่สามารถแก้ไขหรือลบได้)
- **Upload/Update/Delete:** เฉพาะ authenticated users (admin) เท่านั้น

---

## 📋 ขั้นตอนการสร้าง Bucket

### ขั้นที่ 1: เข้าสู่ Storage ใน Supabase Dashboard

1. เปิด [Supabase Dashboard](https://app.supabase.com)
2. เลือก Project `runnerpao`
3. คลิกที่ **Storage** ในเมนูด้านซ้าย (ไอคอนรูปโฟลเดอร์)

---

### ขั้นที่ 2: สร้าง Bucket ใหม่

1. คลิกปุ่ม **"New bucket"** หรือ **"Create a new bucket"** (มุมบนขวา)

2. กรอกข้อมูล Bucket:

   ```
   Name: runner_photos
   ```
   
   **สำคัญ:** ชื่อต้องเป็นตัวพิมพ์เล็กทั้งหมด ไม่มีช่องว่าง (ใช้ underscore _ แทน)

3. เลือกตัวเลือก:
   
   **✅ Public bucket:** เปิด (เพื่อให้ดูรูปภาพได้โดยไม่ต้อง authenticate)
   
   เหตุผล: นักวิ่งต้องสามารถเห็นรูปของตัวเองในหน้า BibPassDisplay ได้

4. (Optional) ตั้งค่าเพิ่มเติม:
   ```
   File size limit: 5 MB
   Allowed MIME types: image/jpeg, image/png, image/webp
   ```

5. คลิก **"Create bucket"**

---

### ขั้นที่ 3: ตั้งค่า Storage Policies

หลังจากสร้าง bucket แล้ว ต้องตั้งค่า policies เพื่อควบคุมการเข้าถึง

#### A. เข้าสู่หน้าตั้งค่า Policies

1. คลิกที่ bucket `runner_photos` ที่เพิ่งสร้าง
2. คลิกแท็บ **"Policies"** (อยู่ด้านบน)
3. คลิกปุ่ม **"New Policy"**

---

#### B. สร้าง Policy ที่ 1: Public Read (อนุญาตให้ทุกคนอ่านได้)

1. คลิก **"New Policy"**
2. เลือก **"For full customization"** หรือ **"Create a policy from scratch"**
3. กรอกข้อมูล:

   **Policy name:**
   ```
   Public Access - Allow everyone to read
   ```

   **Allowed operation:**
   - ✅ SELECT (อ่าน)

   **Target roles:**
   - ✅ public
   - ✅ anon
   - ✅ authenticated

   **USING expression (Policy check):**
   ```sql
   bucket_id = 'runner_photos'
   ```

4. คลิก **"Review"** แล้วคลิก **"Save policy"**

**หรือใช้ SQL นี้ใน SQL Editor:**
```sql
CREATE POLICY "Public Access for runner photos"
ON storage.objects FOR SELECT
USING ( bucket_id = 'runner_photos' );
```

---

#### C. สร้าง Policy ที่ 2: Authenticated Upload (อนุญาตให้ authenticated users อัปโหลดได้)

1. คลิก **"New Policy"** อีกครั้ง
2. เลือก **"Create a policy from scratch"**
3. กรอกข้อมูล:

   **Policy name:**
   ```
   Authenticated Upload - Allow admins to upload
   ```

   **Allowed operation:**
   - ✅ INSERT (สร้างไฟล์ใหม่)

   **Target roles:**
   - ✅ authenticated

   **WITH CHECK expression:**
   ```sql
   bucket_id = 'runner_photos'
   ```

4. คลิก **"Review"** แล้วคลิก **"Save policy"**

**หรือใช้ SQL นี้:**
```sql
CREATE POLICY "Authenticated users can upload runner photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'runner_photos' );
```

---

#### D. สร้าง Policy ที่ 3: Authenticated Update (อนุญาตให้แก้ไขได้)

**SQL:**
```sql
CREATE POLICY "Authenticated users can update runner photos"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'runner_photos' );
```

---

#### E. สร้าง Policy ที่ 4: Authenticated Delete (อนุญาตให้ลบได้)

**SQL:**
```sql
CREATE POLICY "Authenticated users can delete runner photos"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'runner_photos' );
```

---

### ขั้นที่ 4: ตรวจสอบว่าสร้างสำเร็จ

#### A. ตรวจสอบ Bucket

1. ไปที่ **Storage** > คลิก **runner_photos**
2. ควรเห็น bucket ว่างเปล่า พร้อมใช้งาน

#### B. ตรวจสอบ Policies

1. คลิกแท็บ **"Policies"**
2. ควรเห็น policies ทั้ง 4 ตัว:
   - ✅ Public Access (SELECT)
   - ✅ Authenticated Upload (INSERT)
   - ✅ Authenticated Update (UPDATE)
   - ✅ Authenticated Delete (DELETE)

#### C. ทดสอบการอัปโหลด

1. ไปที่หน้า BibPassDisplay ของนักวิ่งคนใดก็ได้
2. ลองอัปโหลดรูปภาพ
3. ถ้าสำเร็จ จะเห็นรูปแสดงใน bucket `runner_photos`

---

## 🚀 วิธีใช้ SQL สร้าง Policies แบบรวดเร็ว

ถ้าต้องการสร้าง policies ทั้งหมดพร้อมกัน ใช้ SQL นี้:

```sql
-- ============================================
-- Storage Policies สำหรับ runner_photos Bucket
-- ============================================

-- Policy 1: อนุญาตให้ทุกคนอ่านได้ (Public Read)
CREATE POLICY "Public Access for runner photos"
ON storage.objects FOR SELECT
USING ( bucket_id = 'runner_photos' );

-- Policy 2: อนุญาตให้ authenticated users อัปโหลดได้ (Upload)
CREATE POLICY "Authenticated users can upload runner photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'runner_photos' );

-- Policy 3: อนุญาตให้ authenticated users แก้ไขได้ (Update)
CREATE POLICY "Authenticated users can update runner photos"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'runner_photos' );

-- Policy 4: อนุญาตให้ authenticated users ลบได้ (Delete)
CREATE POLICY "Authenticated users can delete runner photos"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'runner_photos' );

-- ตรวจสอบว่า policies ถูกสร้างสำเร็จ
SELECT 
    schemaname,
    tablename,
    policyname,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'objects' 
  AND policyname LIKE '%runner photos%'
ORDER BY policyname;
```

วิธีใช้:
1. เปิด **SQL Editor** ใน Supabase Dashboard
2. คัดลอก SQL ด้านบนทั้งหมด
3. วางและคลิก **"Run"** (Ctrl+Enter)
4. ✅ เสร็จแล้ว!

---

## 🔍 ตรวจสอบ Bucket URL

หลังสร้างเสร็จ URL ของ bucket จะเป็น:

```
https://[project-ref].supabase.co/storage/v1/object/public/runner_photos/[file-path]
```

ตัวอย่าง:
```
https://jvghgllatudnusmcrmcb.supabase.co/storage/v1/object/public/runner_photos/1736438472000_runner_001.jpg
```

---

## 📊 โครงสร้างไฟล์ที่แนะนำ

```
runner_photos/
├── 1736438472000_runner_001.jpg
├── 1736438473000_runner_002.jpg
├── 1736438474000_runner_003.jpg
└── ...
```

ชื่อไฟล์จะเป็น: `[timestamp]_[original-filename].[ext]`

---

## 🛠️ การจัดการไฟล์

### ดูไฟล์ทั้งหมดใน Bucket

```sql
SELECT 
    name,
    bucket_id,
    created_at,
    updated_at,
    last_accessed_at,
    metadata->>'size' as size_bytes
FROM storage.objects
WHERE bucket_id = 'runner_photos'
ORDER BY created_at DESC;
```

### ลบไฟล์ที่ไม่ใช้แล้ว

```sql
-- ลบไฟล์ที่ไม่มี runner ใช้แล้ว (orphaned files)
DELETE FROM storage.objects
WHERE bucket_id = 'runner_photos'
  AND name NOT IN (
    SELECT SUBSTRING(runner_photo_url FROM 'runner_photos/(.+)$')
    FROM runners
    WHERE runner_photo_url IS NOT NULL
      AND runner_photo_url LIKE '%runner_photos/%'
  );
```

---

## 🆘 Troubleshooting

### ❌ ปัญหา: อัปโหลดไม่ได้

**สาเหตุ:**
- Bucket ไม่ public
- Policies ไม่ถูกต้อง
- ไม่ได้ login (สำหรับ authenticated upload)

**วิธีแก้:**
1. ตรวจสอบว่า bucket เป็น public
2. ตรวจสอบ policies ว่าครบทั้ง 4 ตัว
3. ตรวจสอบว่า login แล้ว (ถ้าเป็น authenticated user)

### ❌ ปัญหา: รูปไม่แสดง

**สาเหตุ:**
- Bucket ไม่ public
- URL ไม่ถูกต้อง

**วิธีแก้:**
1. ตรวจสอบว่า bucket เป็น public
2. ตรวจสอบ URL ว่าเป็นรูปแบบ:
   ```
   https://[project-ref].supabase.co/storage/v1/object/public/runner_photos/[filename]
   ```

### ❌ ปัญหา: Error "RLS policy violation"

**สาเหตุ:**
- Policies ไม่ถูกต้อง

**วิธีแก้:**
- ลบ policies เดิมและสร้างใหม่:
  ```sql
  -- ลบ policies เดิม
  DROP POLICY IF EXISTS "Public Access for runner photos" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can upload runner photos" ON storage.objects;
  
  -- สร้างใหม่ (ใช้ SQL จากด้านบน)
  ```

---

## 📚 เอกสารที่เกี่ยวข้อง

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [Storage Policies Documentation](https://supabase.com/docs/guides/storage/security/access-control)
- [RUNNER_PHOTO_SETUP.md](./RUNNER_PHOTO_SETUP.md) - คู่มือใช้งานรูปภาพนักวิ่ง

---

## ✅ Checklist

- [ ] สร้าง bucket `runner_photos` แล้ว
- [ ] ตั้งเป็น Public bucket
- [ ] สร้าง Policy: Public Read (SELECT)
- [ ] สร้าง Policy: Authenticated Upload (INSERT)
- [ ] สร้าง Policy: Authenticated Update (UPDATE)
- [ ] สร้าง Policy: Authenticated Delete (DELETE)
- [ ] ทดสอบอัปโหลดรูปภาพแล้ว
- [ ] ทดสอบดูรูปภาพแล้ว

---

**สร้างโดย:** Project-Fang Team  
**วันที่อัปเดตล่าสุด:** 2026-01-09

