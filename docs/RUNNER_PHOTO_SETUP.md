# 📸 คู่มือ: เพิ่มรูปภาพนักวิ่ง (Runner Photo)

คู่มือการตั้งค่าและใช้งานฟีเจอร์รูปภาพนักวิ่ง

---

## 🎯 ภาพรวม

ระบบจะเก็บ URL ของรูปภาพนักวิ่งใน column `runner_photo_url` ของ table `runners` โดยรูปภาพจริงจะอัปโหลดไปยัง Supabase Storage

---

## 📋 ขั้นตอนการตั้งค่า

### 1️⃣ เพิ่ม Column ใน Database

รัน SQL นี้ใน **SQL Editor**:

```sql
-- เพิ่ม column สำหรับเก็บ URL รูปภาพ
ALTER TABLE runners 
ADD COLUMN IF NOT EXISTS runner_photo_url TEXT;

-- เพิ่ม index
CREATE INDEX IF NOT EXISTS idx_runners_has_photo 
ON runners(runner_photo_url) 
WHERE runner_photo_url IS NOT NULL;

-- เพิ่ม comment
COMMENT ON COLUMN runners.runner_photo_url IS 'URL ของรูปภาพนักวิ่ง';
```

หรือใช้ไฟล์: `supabase_schema_add_runner_photo.sql`

---

### 2️⃣ สร้าง Storage Bucket สำหรับรูปภาพนักวิ่ง

#### A. สร้าง Bucket

1. ไปที่ **Storage** ใน Supabase Dashboard
2. คลิก **"New bucket"**
3. กรอกข้อมูล:
   ```
   Name: runner_photos
   Public bucket: ✅ เปิด (เพื่อให้แสดงรูปได้)
   File size limit: 5 MB (ปรับตามต้องการ)
   Allowed MIME types: image/jpeg, image/png, image/webp
   ```
4. คลิก **"Create bucket"**

#### B. ตั้งค่า Storage Policies

ไปที่ bucket `runner_photos` > **Policies** และเพิ่ม policies เหล่านี้:

**Policy 1: อนุญาตให้ทุกคนอ่านได้**
```sql
CREATE POLICY "Public Access for runner photos"
ON storage.objects FOR SELECT
USING ( bucket_id = 'runner_photos' );
```

**Policy 2: อนุญาตให้ authenticated users upload**
```sql
CREATE POLICY "Authenticated users can upload runner photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'runner_photos' );
```

**Policy 3: อนุญาตให้ authenticated users update**
```sql
CREATE POLICY "Authenticated users can update runner photos"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'runner_photos' );
```

**Policy 4: อนุญาตให้ authenticated users delete**
```sql
CREATE POLICY "Authenticated users can delete runner photos"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'runner_photos' );
```

---

### 3️⃣ เพิ่มฟีเจอร์ Upload รูปใน Frontend

#### A. อัปเดต FileUpload Component (สำหรับ Excel)

เพิ่มคอลัมน์ `runner_photo_url` ในการ map Excel:

```typescript
// ใน components/FileUpload.tsx
const RUNNER_FIELDS = [
  // ... existing fields
  { key: 'runner_photo_url', label: 'Runner Photo URL', required: false },
];
```

#### B. สร้าง Component สำหรับ Upload รูป

```typescript
// components/RunnerPhotoUpload.tsx
import React, { useState } from 'react';
import { uploadPassAsset } from '../services/supabaseService';
import Button from './Button';

interface RunnerPhotoUploadProps {
  runnerId: string;
  currentPhotoUrl?: string | null;
  onUploadSuccess: (photoUrl: string) => void;
}

const RunnerPhotoUpload: React.FC<RunnerPhotoUploadProps> = ({
  runnerId,
  currentPhotoUrl,
  onUploadSuccess,
}) => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      
      // Validate file type
      if (!file.type.startsWith('image/')) {
        setError('กรุณาเลือกไฟล์รูปภาพ');
        return;
      }
      
      // Validate file size (5MB)
      if (file.size > 5 * 1024 * 1024) {
        setError('ไฟล์ใหญ่เกิน 5MB');
        return;
      }
      
      setSelectedFile(file);
      setError(null);
    }
  };

  const handleUpload = async () => {
    if (!selectedFile) return;
    
    setUploading(true);
    setError(null);
    
    try {
      // Upload to Supabase Storage
      const result = await uploadPassAsset(selectedFile);
      
      if (result.error) {
        setError(result.error);
        return;
      }
      
      if (result.data) {
        // Update runner record with photo URL
        const { updateRunner } = await import('../services/supabaseService');
        const updateResult = await updateRunner({
          id: runnerId,
          runner_photo_url: result.data,
        });
        
        if (updateResult.error) {
          setError(updateResult.error);
          return;
        }
        
        onUploadSuccess(result.data);
        setSelectedFile(null);
      }
    } catch (err: any) {
      setError(err.message || 'เกิดข้อผิดพลาดในการอัปโหลด');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="space-y-4">
      {currentPhotoUrl && (
        <div className="mb-4">
          <p className="text-sm text-gray-400 mb-2">รูปภาพปัจจุบัน:</p>
          <img
            src={currentPhotoUrl}
            alt="Runner"
            className="w-32 h-32 object-cover rounded-lg"
          />
        </div>
      )}
      
      <div>
        <input
          type="file"
          accept="image/*"
          onChange={handleFileChange}
          className="block w-full text-sm text-gray-400
            file:mr-4 file:py-2 file:px-4
            file:rounded-md file:border-0
            file:text-sm file:font-semibold
            file:bg-blue-600 file:text-white
            hover:file:bg-blue-700"
        />
      </div>
      
      {selectedFile && (
        <div className="flex items-center space-x-2">
          <p className="text-sm text-gray-400">
            เลือกไฟล์: {selectedFile.name}
          </p>
          <Button
            onClick={handleUpload}
            loading={uploading}
            disabled={uploading}
            className="text-sm"
          >
            อัปโหลด
          </Button>
        </div>
      )}
      
      {error && (
        <p className="text-sm text-red-400">{error}</p>
      )}
    </div>
  );
};

export default RunnerPhotoUpload;
```

---

## 💡 วิธีการใช้งาน

### วิธีที่ 1: อัปโหลดผ่าน Excel

1. เพิ่มคอลัมน์ `runner_photo_url` ในไฟล์ Excel
2. ใส่ URL ของรูปภาพ (ต้อง upload ไปที่ Supabase Storage ก่อน)
3. Upload Excel ตามปกติ

### วิธีที่ 2: อัปโหลดผ่าน UI (แนะนำ)

1. ไปที่หน้าแก้ไขข้อมูล Runner
2. เลือกไฟล์รูปภาพ
3. คลิก "อัปโหลด"
4. รูปจะถูก upload ไปยัง Storage และ URL จะถูกบันทึกอัตโนมัติ

### วิธีที่ 3: อัปโหลดผ่าน Code/Script

```typescript
import { uploadPassAsset, updateRunner } from './services/supabaseService';

async function uploadRunnerPhoto(runnerId: string, photoFile: File) {
  // 1. Upload photo to Storage
  const uploadResult = await uploadPassAsset(photoFile);
  
  if (uploadResult.error) {
    console.error('Upload failed:', uploadResult.error);
    return;
  }
  
  // 2. Update runner record with photo URL
  const updateResult = await updateRunner({
    id: runnerId,
    runner_photo_url: uploadResult.data,
  });
  
  if (updateResult.error) {
    console.error('Update failed:', updateResult.error);
    return;
  }
  
  console.log('Photo uploaded successfully:', uploadResult.data);
}
```

---

## 🎨 การแสดงรูปภาพใน Bib Pass

### เพิ่มรูปภาพใน Web Pass Template

ในการตั้งค่า Web Pass Config:

```typescript
{
  id: 'template_1',
  name: 'Template with Photo',
  fields: [
    // ... other fields
    {
      id: 'runner_photo',
      key: 'profile_picture', // Special key for photo
      label: 'Runner Photo',
      profilePicture: runner.runner_photo_url || 'default-avatar.png',
      profileWidth: 120,
      profileHeight: 120,
      profileShape: 'circle', // or 'square'
      x: 50,
      y: 20,
      // ... other properties
    }
  ]
}
```

---

## 📏 แนะนำขนาดรูปภาพ

| ประเภท | ขนาดแนะนำ | Format |
|--------|-----------|--------|
| Profile Photo | 400x400px | JPEG, PNG, WebP |
| Display on Pass | 300x300px | JPEG, PNG |
| Thumbnail | 150x150px | JPEG, PNG |

**Tips:**
- ใช้รูปสี่เหลี่ยมจัตุรัส (aspect ratio 1:1) จะดูดีที่สุด
- ขนาดไฟล์ไม่เกิน 5MB
- แนะนำให้ใช้ WebP สำหรับประสิทธิภาพที่ดี

---

## 🔧 การ Optimize รูปภาพ

### ใช้ Image Transformation

Supabase Storage รองรับ image transformation:

```typescript
// Original URL
const originalUrl = runner.runner_photo_url;

// Resized URL (400x400)
const resizedUrl = `${originalUrl}?width=400&height=400`;

// With quality
const optimizedUrl = `${originalUrl}?width=400&height=400&quality=80`;
```

### Pre-process ก่อน Upload

```typescript
async function compressImage(file: File, maxWidth: number = 800): Promise<File> {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = (e) => {
      const img = new Image();
      img.src = e.target?.result as string;
      img.onload = () => {
        const canvas = document.createElement('canvas');
        let width = img.width;
        let height = img.height;
        
        if (width > maxWidth) {
          height = (height * maxWidth) / width;
          width = maxWidth;
        }
        
        canvas.width = width;
        canvas.height = height;
        
        const ctx = canvas.getContext('2d');
        ctx?.drawImage(img, 0, 0, width, height);
        
        canvas.toBlob((blob) => {
          const compressedFile = new File([blob!], file.name, {
            type: 'image/jpeg',
            lastModified: Date.now(),
          });
          resolve(compressedFile);
        }, 'image/jpeg', 0.8);
      };
    };
  });
}
```

---

## 🔍 Query Runners ที่มีรูปภาพ

```sql
-- ดึง runners ที่มีรูปภาพ
SELECT id, bib, first_name, last_name, runner_photo_url
FROM runners
WHERE runner_photo_url IS NOT NULL
ORDER BY created_at DESC;

-- นับจำนวน runners ที่มีรูปภาพ
SELECT 
  COUNT(*) as total_runners,
  COUNT(runner_photo_url) as runners_with_photo,
  ROUND(COUNT(runner_photo_url)::NUMERIC / COUNT(*) * 100, 2) as percentage
FROM runners;
```

---

## 🆘 Troubleshooting

### ❌ ปัญหา: อัปโหลดไม่ได้

**แก้:**
- ตรวจสอบว่าสร้าง bucket `runner_photos` แล้ว
- ตรวจสอบ Storage policies
- ตรวจสอบขนาดไฟล์ (ไม่เกิน 5MB)

### ❌ ปัญหา: รูปไม่แสดง

**แก้:**
- ตรวจสอบว่า bucket เป็น Public
- ตรวจสอบ URL ว่าถูกต้อง
- ตรวจสอบ CORS settings

### ❌ ปัญหา: รูปเพี้ยน

**แก้:**
- ใช้รูปสี่เหลี่ยมจัตุรัส (1:1)
- ตั้งค่า `object-fit: cover` ใน CSS
- Resize รูปก่อน upload

---

## 📚 เอกสารที่เกี่ยวข้อง

- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)
- [QUICK_START_RUNNERPAO.md](./QUICK_START_RUNNERPAO.md)
- [UPLOAD_IMAGE_TO_SUPABASE.md](./UPLOAD_IMAGE_TO_SUPABASE.md)

---

**สร้างโดย:** Project-Fang Team  
**วันที่อัปเดตล่าสุด:** 2026-01-09

