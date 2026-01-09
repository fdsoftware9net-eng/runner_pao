# 🔐 Setup Authentication สำหรับ runnerpao

คู่มือการตั้งค่า Authentication และสร้าง Admin User ใน Supabase project ใหม่

---

## 🎯 ขั้นตอนการตั้งค่า

### 1️⃣ ปิด Email Confirmation (สำหรับ Development)

เพื่อให้สามารถ login ได้ทันทีโดยไม่ต้องรอยืนยัน email

1. ไปที่ **Authentication** (เมนูซ้าย) ใน Supabase Dashboard
2. คลิกที่ **Providers**
3. เลื่อนลงไปหา **Email** provider
4. คลิก **Edit** หรือ Configure
5. **ปิด "Confirm email"** (toggle off) ✅
6. คลิก **Save**

> **⚠️ สำคัญ:** สำหรับ Production ควรเปิด email confirmation กลับมา

---

### 2️⃣ สร้าง Admin User

มี 2 วิธีในการสร้าง user:

#### **วิธีที่ 1: สร้างผ่าน Supabase Dashboard (แนะนำ)**

1. ไปที่ **Authentication** > **Users** ใน Supabase Dashboard
2. คลิก **"Add user"** หรือ **"+ Create user"**
3. เลือก **"Create new user"**
4. กรอกข้อมูล:
   ```
   Email: admin@yourcompany.com (หรืออีเมลที่คุณต้องการ)
   Password: YourSecurePassword123! (อย่างน้อย 6 ตัวอักษร)
   ```
5. **ปิด** checkbox "Send email confirmation" (ถ้ามี)
6. คลิก **"Create user"** หรือ **"Save"**

#### **วิธีที่ 2: สร้างผ่าน SQL**

รัน SQL นี้ใน **SQL Editor**:

```sql
-- สร้าง Admin User ผ่าน SQL
-- ⚠️ เปลี่ยน email และ password ให้ตรงกับที่คุณต้องการ
-- Password จะถูก hash อัตโนมัติ

-- แทรก user ใหม่
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@yourcompany.com', -- 🔸 เปลี่ยนอีเมลที่นี่
  crypt('YourSecurePassword123!', gen_salt('bf')), -- 🔸 เปลี่ยนรหัสผ่านที่นี่
  NOW(), -- Email confirmed (ข้าม confirmation)
  NULL,
  NULL,
  '{"provider":"email","providers":["email"]}',
  '{}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);

-- สร้าง identity record
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT 
  gen_random_uuid(),
  id,
  format('{"sub":"%s","email":"%s"}', id::text, email)::jsonb,
  'email',
  NOW(),
  NOW(),
  NOW()
FROM auth.users
WHERE email = 'admin@yourcompany.com'; -- 🔸 ใช้อีเมลเดียวกับด้านบน
```

---

### 3️⃣ ตรวจสอบว่า User ถูกสร้างสำเร็จ

1. ไปที่ **Authentication** > **Users**
2. ควรเห็น user ที่สร้างไว้
3. ตรวจสอบว่า:
   - **Email Confirmed:** ✅ (สีเขียว)
   - **Created At:** เวลาที่เพิ่งสร้าง

---

### 4️⃣ ทดสอบ Login

1. เปิด browser ไปที่ `http://localhost:5173` (หรือ URL ของคุณ)
2. จะเห็นหน้า **Login Page**
3. กรอก:
   ```
   Email: admin@yourcompany.com (หรืออีเมลที่คุณสร้างไว้)
   Password: YourSecurePassword123! (รหัสผ่านที่คุณตั้งไว้)
   ```
4. คลิก **"Sign In"**
5. ถ้าสำเร็จ จะเข้าสู่ **Admin Dashboard** ได้เลย ✅

---

## 🔒 สร้าง Admin User เพิ่มเติม

ถ้าต้องการสร้าง admin user เพิ่ม ทำซ้ำขั้นตอนที่ 2

**แนะนำ:** ใช้วิธีที่ 1 (Dashboard) เพราะง่ายและไม่ต้องกังวลเรื่อง password hashing

---

## 🛡️ Best Practices สำหรับ Production

### 1. เปิด Email Confirmation

1. ไปที่ **Authentication** > **Providers** > **Email**
2. **เปิด "Confirm email"** (toggle on)
3. Save

### 2. ตั้งค่า Email Provider

Supabase ใช้ built-in SMTP แต่มีข้อจำกัดสำหรับ production

**แนะนำ:** ใช้ Custom SMTP (เช่น SendGrid, Resend, AWS SES)

1. ไปที่ **Project Settings** > **Auth** > **SMTP Settings**
2. เปิด **"Enable Custom SMTP"**
3. กรอกข้อมูล SMTP:
   ```
   Sender email: noreply@yourdomain.com
   Sender name: Your App Name
   Host: smtp.sendgrid.net (หรือ provider ของคุณ)
   Port: 587
   Username: apikey (สำหรับ SendGrid)
   Password: [Your SMTP Password/API Key]
   ```
4. คลิก **"Save"**

### 3. ตั้งค่า Email Templates

1. ไปที่ **Authentication** > **Email Templates**
2. แก้ไข templates:
   - **Confirm signup** (ยืนยันอีเมล)
   - **Invite user** (เชิญผู้ใช้)
   - **Magic Link** (ถ้าใช้)
   - **Reset password** (รีเซ็ตรหัสผ่าน)

### 4. ตั้งค่า Password Policy

1. ไปที่ **Authentication** > **Policies**
2. ตั้งค่า:
   ```
   Minimum password length: 8 (หรือมากกว่า)
   Require lowercase: ✅
   Require uppercase: ✅
   Require numbers: ✅
   Require symbols: ✅
   ```

### 5. จำกัด Rate Limiting

1. ไปที่ **Authentication** > **Rate Limits**
2. ตั้งค่า:
   ```
   Max attempts: 5 (จำกัดการ login ผิด)
   Time window: 15 minutes
   ```

---

## 🆘 Troubleshooting

### ❌ ปัญหา: Login ไม่ได้ (Invalid login credentials)

**สาเหตุที่เป็นไปได้:**
1. Email หรือ Password ผิด
2. User ยังไม่ได้ confirm email (ถ้าเปิด email confirmation)
3. User ถูก disable

**วิธีแก้:**
1. ตรวจสอบ email และ password ให้แน่ใจ
2. ไปที่ **Authentication** > **Users** ดู user ที่สร้างไว้
3. ตรวจสอบว่า **Email Confirmed** เป็น ✅
4. ถ้ายังไม่ confirm ให้คลิกที่ user > **Confirm email** (3 dots menu)

### ❌ ปัญหา: User สร้างแล้วแต่ไม่เห็นใน Dashboard

**วิธีแก้:**
- Refresh หน้า Dashboard
- ตรวจสอบด้วย SQL:
  ```sql
  SELECT id, email, email_confirmed_at, created_at
  FROM auth.users
  ORDER BY created_at DESC;
  ```

### ❌ ปัญหา: ได้รับ error "Email rate limit exceeded"

**วิธีแก้:**
- รอสักครู่ (15-60 นาที)
- หรือสร้าง user ผ่าน Dashboard แทน (ไม่ส่ง email)

### ❌ ปัญหา: หลัง login แล้วถูก redirect กลับไปหน้า login

**วิธีแก้:**
1. เช็ค Browser Console (F12) ดู error
2. ตรวจสอบว่า `.env` มี URL และ ANON_KEY ถูกต้อง
3. Clear browser cache และ cookies
4. ลองใน Incognito/Private mode

---

## 📝 Quick Reference

### สร้าง Admin User ด่วน (วิธีที่ง่ายที่สุด)

1. **Authentication** > **Users** > **"Add user"**
2. Email: `admin@yourcompany.com`
3. Password: `YourPassword123!`
4. **ปิด** "Send email confirmation"
5. **Create user**
6. ✅ Login ได้ทันที!

---

## 🔗 เอกสารที่เกี่ยวข้อง

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [QUICK_START_RUNNERPAO.md](./QUICK_START_RUNNERPAO.md) - Setup Guide
- [MIGRATE_TO_NEW_SUPABASE_PROJECT.md](./MIGRATE_TO_NEW_SUPABASE_PROJECT.md) - Migration Guide

---

**สร้างโดย:** Project-Fang Team  
**วันที่อัปเดตล่าสุด:** 2026-01-09

