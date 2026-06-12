-- ============================================================
-- เปิดให้ "ทุกคนดูได้โดยไม่ต้อง login" (อ่านอย่างเดียว)
-- แต่ "แก้ไขได้เฉพาะ จนท.คลัง" ที่ login เท่านั้น
-- ------------------------------------------------------------
-- วิธีใช้: Supabase Dashboard → SQL Editor → New query →
--          paste ทั้งหมด → Run  (รันครั้งเดียว)
-- ============================================================

do $$
declare t text;
begin
  for t in select unnest(array['items','workers','vehicles','teams','movements','app_meta']) loop
    -- อนุญาตให้ผู้เยี่ยมชม (anon) อ่านข้อมูลได้อย่างเดียว
    execute format('drop policy if exists "public_read" on %I', t);
    execute format(
      'create policy "public_read" on %I for select to anon using (true)', t
    );
  end loop;
end$$;

-- หมายเหตุ: นโยบาย "auth_all" (เขียน/แก้ไข/ลบ เฉพาะ authenticated) ยังคงอยู่เหมือนเดิม
-- ผู้เยี่ยมชมที่ไม่ได้ login จะ "เขียนไม่ได้" เพราะไม่มี policy ให้ anon insert/update/delete
