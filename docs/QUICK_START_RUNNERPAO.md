# 🚀 Quick Start Guide: แยก Supabase Project เป็น runnerpao

คู่มือฉบับย่อสำหรับการย้ายไปใช้ Supabase project ใหม่ชื่อ `runnerpao`

---

## ✅ Checklist 6 ขั้นตอน

### 1️⃣ สร้าง Supabase Project ใหม่

1. ไป [https://app.supabase.com](https://app.supabase.com)
2. คลิก **"New Project"**
3. ตั้งชื่อ: `runnerpao`
4. เลือก Region: **Singapore (ap-southeast-1)**
5. ตั้ง Database Password (เก็บไว้ดี ๆ!) 
6. คลิก **"Create new project"** และรอ 2-5 นาที

---

### 2️⃣ Copy API Credentials

1. ไปที่ **Settings > API** ใน Supabase Dashboard
2. คัดลอก:
   - **Project URL:** `https://xxxxx.supabase.co` 
   - **anon public key:** `eyJxxx...` 
3. เก็บไว้ในที่ปลอดภัย

---

### 3️⃣ Run Database Schema Migration

1. ไปที่ **SQL Editor** ใน Supabase Dashboard
2. คัดลอกเนื้อหาทั้งหมดจากไฟล์: **`supabase_schema_full_migration_runnerpao.sql`**
3. วางใน SQL Editor
4. คลิก **"Run"** (หรือ Ctrl+Enter)
5. รอจนเสร็จ (ประมาณ 10-30 วินาที)

**ตรวจสอบว่าสำเร็จ:**
```sql
-- Run คำสั่งนี้เพื่อดู tables ที่ถูกสร้าง
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- ควรเห็น: runners, wallet_config, user_activity_logs
```

---

### 4️⃣ ตั้งค่า Authentication และสร้าง Admin User

#### ปิด Email Confirmation (สำหรับ Development)

1. ไปที่ **Authentication** (เมนูซ้าย)
2. คลิก **Providers**
3. หา **Email** provider และคลิก Edit
4. **ปิด "Confirm email"** (toggle off) ✅
5. คลิก **Save**

#### สร้าง Admin User

1. ไปที่ **Authentication** > **Users**
2. คลิก **"Add user"** หรือ **"Create user"**
3. กรอกข้อมูล:
   ```
   Email: admin@yourcompany.com
   Password: YourPassword123!
   ```
4. **ปิด** "Send email confirmation" (ถ้ามี)
5. คลิก **"Create user"**

> 📚 ดูรายละเอียดเพิ่มเติม: [SETUP_AUTHENTICATION.md](./SETUP_AUTHENTICATION.md)

---

### 5️⃣ สร้าง Storage Bucket

1. ไปที่ **Storage** (เมนูซ้าย)
2. คลิก **"New bucket"**
3. ตั้งชื่อ: `pass_assets`
4. เปิด **"Public bucket"** ✅
5. คลิก **"Create bucket"**

**ตั้งค่า Policies:**

ไปที่ bucket `pass_assets` > **Policies**

**Policy 1: Public Read**
```sql
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'pass_assets' );
```

**Policy 2: Authenticated Upload**
```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'pass_assets' );
```

---

### 6️⃣ อัปเดต Frontend Configuration

**Option A: Local Development (ใช้ไฟล์ .env)**

1. คัดลอกไฟล์ `.env.example` เป็น `.env`
2. แก้ไขค่าใน `.env`:

```env
VITE_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx...
```

3. รัน dev server:
```bash
npm run dev
```

**Option B: Production (Vercel/Hosting)**

1. ไปที่ **Vercel Dashboard** > Project > **Settings > Environment Variables**
2. เพิ่ม:
   ```
   VITE_SUPABASE_URL = https://xxxxx.supabase.co
   VITE_SUPABASE_ANON_KEY = eyJxxx...
   ```
3. Redeploy

---

## 🧪 ทดสอบว่าทำงาน

### ทดสอบการเชื่อมต่อ

```bash
npm run dev
```

เปิด browser ที่ `http://localhost:5173` และทดสอบ:

- [ ] เข้า Admin Dashboard
- [ ] Upload Excel file
- [ ] ค้นหา Runner (ลองค้นหาด้วย BIB หรือชื่อ)
- [ ] ดูรายการ Runners

---

## 🎯 Deploy Edge Functions (Optional - ถ้าต้องการ Wallet Passes)

### ติดตั้ง Supabase CLI

```bash
# Windows (PowerShell)
scoop install supabase

# หรือใช้ npm
npm install -g supabase
```

### Login และ Deploy

```bash
# Login
supabase login

# Link project (หา project-ref จาก Settings > General > Reference ID)
supabase link --project-ref xxxxxxxxxxxxx

# Deploy ทุก functions
supabase functions deploy
```

### ตั้งค่า Secrets

```bash
# Apple Wallet Secrets
supabase secrets set APPLE_PASS_TYPE_IDENTIFIER=pass.com.yourcompany.runner
supabase secrets set APPLE_TEAM_IDENTIFIER=XXXXXXXXXX
supabase secrets set APPLE_CERTIFICATE_P12=<base64-encoded-p12>
supabase secrets set APPLE_CERTIFICATE_PASSWORD=your-password

# Google Wallet Secrets
supabase secrets set GOOGLE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
supabase secrets set GOOGLE_WALLET_ISSUER_ID=your-issuer-id

# Email Secrets (Resend)
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxx
supabase secrets set FROM_EMAIL=noreply@yourdomain.com
```

---

## 📊 Migrate Data (Optional - ถ้าต้องการย้ายข้อมูลจาก Project เก่า)

### Export จาก Project เก่า

1. ไปที่ SQL Editor ของ project `runnerbibpass`
2. รัน:
```sql
SELECT * FROM runners;
```
3. Export เป็น CSV

### Import ไป Project ใหม่

**วิธีที่ 1: ใช้ Admin Dashboard**
- Upload Excel file ผ่าน UI

**วิธีที่ 2: ใช้ SQL**
```sql
-- Import from CSV (ต้องอัปโหลดไฟล์ไปที่ Supabase Storage ก่อน)
-- หรือใช้ Supabase Dashboard > Table Editor > Insert rows
```

---

## 🆘 Troubleshooting

### ❌ ปัญหา: Schema migration ล้มเหลว
**แก้:** ตรวจสอบว่าไม่มี syntax error และรันใน SQL Editor ทั้งหมดพร้อมกัน

### ❌ ปัญหา: Frontend ไม่เชื่อมต่อ Supabase
**แก้:** 
- ตรวจสอบ `.env` ว่ามี URL และ ANON_KEY ถูกต้อง
- Restart dev server (`npm run dev`)
- Clear browser cache

### ❌ ปัญหา: Upload ไฟล์ไม่ได้
**แก้:** 
- ตรวจสอบว่าสร้าง bucket `pass_assets` แล้ว
- ตรวจสอบ Storage policies ว่าตั้งค่าถูกต้อง

### ❌ ปัญหา: Edge Functions ไม่ทำงาน
**แก้:**
- ตรวจสอบ secrets: `supabase secrets list`
- ดู logs: `supabase functions logs <function-name>`

---

## 📚 เอกสารเพิ่มเติม

- [MIGRATE_TO_NEW_SUPABASE_PROJECT.md](./MIGRATE_TO_NEW_SUPABASE_PROJECT.md) - คู่มือแบบละเอียด
- [DEPLOY.md](../DEPLOY.md) - Deployment Guide
- [ANALYTICS_GUIDE.md](./ANALYTICS_GUIDE.md) - Analytics Features

---

## ✨ เสร็จแล้ว!

ตอนนี้คุณมี Supabase project ใหม่ชื่อ `runnerpao` ที่แยกออกจาก `runnerbibpass` แล้ว 🎉

**Next Steps:**
1. ทดสอบทุกฟีเจอร์ให้มั่นใจ
2. Deploy ไป Production
3. อัปเดต DNS/Domain (ถ้าจำเป็น)
4. Migrate data จาก project เก่า (ถ้าต้องการ)

---

**มีคำถาม?** ดูเอกสารแบบละเอียดได้ที่ [MIGRATE_TO_NEW_SUPABASE_PROJECT.md](./MIGRATE_TO_NEW_SUPABASE_PROJECT.md)

