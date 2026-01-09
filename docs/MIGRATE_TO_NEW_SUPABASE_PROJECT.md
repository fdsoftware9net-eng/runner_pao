# 📚 คู่มือ: แยก Supabase Project ใหม่ (runnerpao)

## 🎯 วัตถุประสงค์
คู่มือนี้จะแนะนำการสร้าง Supabase Project ใหม่ชื่อ `runnerpao` แยกออกจาก `runnerbibpass` โดยใช้ schema เดียวกัน

---

## 📋 สิ่งที่ต้องเตรียม

- [ ] บัญชี Supabase
- [ ] ไฟล์ SQL สำหรับ migration (มีในโปรเจ็คแล้ว)
- [ ] Apple Developer credentials (สำหรับ Apple Wallet Pass)
- [ ] Google Cloud Service Account (สำหรับ Google Wallet Pass)

---

## ขั้นตอนที่ 1: สร้าง Supabase Project ใหม่

### 1.1 สร้าง Project

1. ไปที่ [https://app.supabase.com](https://app.supabase.com)
2. คลิก **"New Project"**
3. กรอกข้อมูล:
   ```
   Project Name: runnerpao
   Database Password: [สร้างรหัสผ่านที่แข็งแกร่ง - เก็บไว้ดี ๆ]
   Region: Southeast Asia (Singapore) - ap-southeast-1
   Pricing Plan: [เลือกตามความเหมาะสม]
   ```
4. คลิก **"Create new project"**
5. รอประมาณ 2-5 นาทีจนสร้างเสร็จ

### 1.2 Copy API Credentials

หลังจาก project สร้างเสร็จ:

1. ไปที่ **Settings** (เมนูซ้ายล่าง) > **API**
2. คัดลอกข้อมูลเหล่านี้:
   ```
   Project URL: https://xxxxxxxxxxxxx.supabase.co
   anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx...
   service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx... (เก็บไว้สำหรับ Edge Functions)
   ```

---

## ขั้นตอนที่ 2: Run Database Schema Migration

### 2.1 เข้าไปที่ SQL Editor

1. ใน Supabase Dashboard ของ project `runnerpao`
2. ไปที่ **SQL Editor** (เมนูซ้าย)

### 2.2 Run Schema File แบบรวม

รัน file: `supabase_schema_full_migration.sql` (ไฟล์นี้รวมทุกอย่างแล้ว)

**หรือ** รัน files ทีละไฟล์ตามลำดับ:

```sql
1. supabase_schema_update.sql           -- สร้าง tables หลัก
2. supabase_schema_update_v2.sql        -- เพิ่ม template rules
3. supabase_schema_update_v3.sql        -- (ถ้ามี)
4. supabase_schema_update_v4.sql        -- (ถ้ามี)
5. supabase_schema_update_v5_safe.sql   -- (ถ้ามี)
6. supabase_schema_update_v6.sql        -- (ถ้ามี)
7. supabase_schema_update_v7.sql        -- (ถ้ามี)
8. supabase_schema_update_v8_rpc_only.sql -- RPC Functions สำคัญมาก!
9. supabase_schema_update_v9_add_link_line_account.sql
10. supabase_schema_update_v10_add_link_line_account_stats.sql
```

> **⚠️ สำคัญ:** ต้องรันตามลำดับ เพราะบางไฟล์พึ่งพา schema จากไฟล์ก่อนหน้า

### 2.3 ตรวจสอบว่า Schema สร้างสำเร็จ

รัน SQL นี้เพื่อตรวจสอบ:

```sql
-- ตรวจสอบ Tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- ควรเห็น: runners, wallet_config, user_activity_logs, etc.

-- ตรวจสอบ RPC Functions
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
ORDER BY routine_name;

-- ควรเห็น: log_user_activity, get_activity_statistics, get_daily_statistics, get_runner_updates
```

---

## ขั้นตอนที่ 3: ตั้งค่า Storage Buckets

### 3.1 สร้าง Storage Bucket สำหรับ Pass Assets

1. ไปที่ **Storage** (เมนูซ้าย)
2. คลิก **"New bucket"**
3. กรอกข้อมูล:
   ```
   Name: pass_assets
   Public bucket: ✅ เปิด (เพื่อให้ดาวน์โหลด images ได้)
   ```
4. คลิก **"Create bucket"**

### 3.2 ตั้งค่า Policies สำหรับ pass_assets

ไปที่ bucket `pass_assets` > **Policies** > **New Policy**

**Policy 1: อนุญาตให้ทุกคนอ่านได้**
```sql
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'pass_assets' );
```

**Policy 2: อนุญาตให้ authenticated users upload ได้**
```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'pass_assets' );
```

---

## ขั้นตอนที่ 4: Deploy Supabase Edge Functions

### 4.1 ติดตั้ง Supabase CLI (ถ้ายังไม่มี)

```bash
# Windows (PowerShell)
scoop install supabase

# หรือใช้ npm
npm install -g supabase
```

### 4.2 Login และ Link Project

```bash
# Login
supabase login

# Link project
supabase link --project-ref xxxxxxxxxxxxx
# (project-ref หาได้จาก Settings > General > Reference ID)
```

### 4.3 Deploy Functions

```bash
# Deploy ทุก functions พร้อมกัน
supabase functions deploy

# หรือ deploy ทีละตัว
supabase functions deploy generate-apple-wallet-pass
supabase functions deploy generate-google-wallet-pass
supabase functions deploy process-excel
supabase functions deploy send-email
```

### 4.4 ตั้งค่า Secrets สำหรับ Functions

```bash
# Secrets สำหรับ Apple Wallet
supabase secrets set APPLE_PASS_TYPE_IDENTIFIER=pass.com.yourcompany.runner
supabase secrets set APPLE_TEAM_IDENTIFIER=XXXXXXXXXX
supabase secrets set APPLE_CERTIFICATE_P12=<base64-encoded-p12-file>
supabase secrets set APPLE_CERTIFICATE_PASSWORD=your-password

# Secrets สำหรับ Google Wallet
supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON=<json-content>
supabase secrets set GOOGLE_WALLET_ISSUER_ID=your-issuer-id

# Secrets สำหรับ Email (Resend)
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxx
supabase secrets set FROM_EMAIL=noreply@yourdomain.com
```

---

## ขั้นตอนที่ 5: อัปเดต Frontend Configuration

### 5.1 อัปเดตไฟล์ `.env` (Local Development)

สร้างหรือแก้ไขไฟล์ `.env` ใน root ของโปรเจ็ค:

```env
# Supabase Configuration - runnerpao project
VITE_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx...

# Optional: Table name override (ใช้ได้ถ้าต้องการทดสอบกับ table ต่างชื่อ)
# VITE_SUPABASE_RUNNERS_TABLE=runners
```

### 5.2 ทดสอบการเชื่อมต่อ

```bash
# รัน dev server
npm run dev
```

เปิดเบราว์เซอร์ที่ `http://localhost:5173` และทดสอบ:
- [ ] Login เข้า Admin Dashboard
- [ ] Upload ไฟล์ Excel
- [ ] ดูข้อมูล Runners
- [ ] ค้นหา Runner
- [ ] Generate Apple/Google Wallet Pass

---

## ขั้นตอนที่ 6: Deploy Frontend ไปยัง Hosting

### 6.1 ตั้งค่า Environment Variables ใน Vercel/Hosting

ถ้าใช้ Vercel:

1. ไปที่ [Vercel Dashboard](https://vercel.com)
2. เลือก Project
3. ไปที่ **Settings** > **Environment Variables**
4. เพิ่มตัวแปรเหล่านี้:
   ```
   VITE_SUPABASE_URL = https://xxxxxxxxxxxxx.supabase.co
   VITE_SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx...
   ```
5. Redeploy project

### 6.2 ตั้งค่า Custom Domain (Optional)

ดู: `VERCEL_DOMAIN_SETUP.md`

---

## ขั้นตอนที่ 7: Migrate Data (ถ้าต้องการย้ายข้อมูล)

### 7.1 Export Data จาก Project เก่า

```bash
# Export ข้อมูล runners
# ไปที่ SQL Editor ของ project เก่า
SELECT * FROM runners;

# Export เป็น CSV และ save ไว้
```

### 7.2 Import Data ไปยัง Project ใหม่

**วิธีที่ 1: ใช้ Admin Dashboard**
- อัปโหลดไฟล์ Excel ผ่าน UI

**วิธีที่ 2: ใช้ SQL**
```sql
-- Copy data from CSV
COPY runners (id, bib, first_name, last_name, email, ...)
FROM '/path/to/runners.csv'
DELIMITER ','
CSV HEADER;
```

---

## ✅ Checklist การ Migrate

- [ ] สร้าง Supabase Project ใหม่ (runnerpao)
- [ ] Copy API Credentials
- [ ] Run Database Schema Migration (ทุกไฟล์ตามลำดับ)
- [ ] ตรวจสอบ Tables และ RPC Functions
- [ ] สร้าง Storage Bucket (pass_assets)
- [ ] ตั้งค่า Storage Policies
- [ ] Deploy Supabase Edge Functions
- [ ] ตั้งค่า Secrets สำหรับ Functions
- [ ] อัปเดตไฟล์ `.env` (Local)
- [ ] ทดสอบการเชื่อมต่อ Local
- [ ] ตั้งค่า Environment Variables ใน Vercel/Hosting
- [ ] Deploy Frontend
- [ ] ทดสอบ Production
- [ ] Migrate Data (ถ้าต้องการ)

---

## 🚨 ข้อควรระวัง

1. **อย่าลืมเก็บ Credentials ให้ปลอดภัย**
   - Database Password
   - Service Role Key
   - API Keys (Apple, Google, Resend)

2. **อย่าเขียนทับไฟล์ `.env`**
   - สำรองไฟล์เก่าไว้ก่อน

3. **ทดสอบให้มั่นใจก่อน Deploy Production**
   - ทดสอบทุกฟีเจอร์ใน Local
   - ทดสอบ Edge Functions
   - ทดสอบ Storage Upload/Download

4. **ตั้งค่า RLS (Row Level Security) ให้ถูกต้อง**
   - ตรวจสอบว่า RPC functions มี `SECURITY DEFINER`
   - ตรวจสอบ Storage policies

---

## 🔗 เอกสารที่เกี่ยวข้อง

- [DEPLOY.md](../DEPLOY.md) - Deployment Guide
- [VERCEL_DOMAIN_SETUP.md](../VERCEL_DOMAIN_SETUP.md) - Custom Domain Setup
- [ANALYTICS_GUIDE.md](./ANALYTICS_GUIDE.md) - Analytics Features
- [RPC_FUNCTIONLOG_SETUP.md](./RPC_FUNCTIONLOG_SETUP.md) - RPC Functions Setup

---

## 💡 Tips

### ทดสอบว่า Functions ทำงานได้

```bash
# Test locally
supabase functions serve

# Test deployed function
curl https://xxxxxxxxxxxxx.supabase.co/functions/v1/generate-apple-wallet-pass \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"runnerId": "test-id"}'
```

### Monitoring

- ดู Logs: **Database** > **Logs**
- ดู API Usage: **Settings** > **Usage**
- ดู Function Logs: **Edge Functions** > เลือก function > **Logs**

---

## 🆘 Troubleshooting

### ปัญหา: Schema Migration ล้มเหลว
**แก้ไข:** ตรวจสอบว่ารันไฟล์ตามลำดับถูกต้อง และไม่มี syntax error

### ปัญหา: Edge Functions ไม่ทำงาน
**แก้ไข:** 
- ตรวจสอบ Secrets (`supabase secrets list`)
- ดู Logs (`supabase functions logs <function-name>`)

### ปัญหา: Frontend ไม่เชื่อมต่อกับ Supabase
**แก้ไข:**
- ตรวจสอบ `.env` ว่า URL และ ANON_KEY ถูกต้อง
- Clear browser cache และ restart dev server

### ปัญหา: Upload ไฟล์ไม่ได้
**แก้ไข:**
- ตรวจสอบว่าสร้าง bucket `pass_assets` แล้ว
- ตรวจสอบ Storage policies

---

**สร้างโดย:** Project-Fang Team  
**วันที่อัปเดตล่าสุด:** 2026-01-09

