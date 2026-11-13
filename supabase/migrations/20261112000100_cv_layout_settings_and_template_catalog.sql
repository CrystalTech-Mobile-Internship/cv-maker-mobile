begin;

-- Presentation settings that must survive a cloud round trip:
-- language, custom section order and hidden sections.
alter table public.cvs
  add column if not exists layout_settings jsonb not null default '{}'::jsonb;

alter table public.cvs drop constraint if exists cvs_layout_settings_is_object;
alter table public.cvs
  add constraint cvs_layout_settings_is_object
  check (jsonb_typeof(layout_settings) = 'object');

-- Keep the cloud template catalog aligned with every template the app ships,
-- otherwise the template_id foreign key rejects synced CVs.
insert into public.templates (id, name, description)
values
  ('harvard_ats', 'Harvard ATS', 'Một cột, ưu tiên hệ thống ATS'),
  ('modern_minimalist', 'Modern Minimalist', 'Hiện đại và tối giản'),
  ('minimalist_clean', 'Minimalist Clean', 'Sạch, phù hợp nhiều ngành'),
  ('creative_tech', 'Creative Tech', 'Dành cho công nghệ và sáng tạo'),
  ('professional_sidebar', 'Professional Sidebar', 'Bố cục 1/3 và 2/3'),
  ('executive_navy', 'Executive Navy', 'Doanh nghiệp, quản lý và kinh doanh'),
  ('academic_classic', 'Academic Classic', 'Giáo dục và nghiên cứu'),
  ('fresh_profile', 'Fresh Profile', 'Marketing, dịch vụ và hồ sơ có ảnh'),
  ('chronological_slate', 'Chronological Slate', 'Trình bày theo thời gian'),
  ('graduate_skills', 'Graduate Skills', 'Sinh viên mới tốt nghiệp, nhấn mạnh kỹ năng'),
  ('finance_precision', 'Finance Precision', 'Tài chính, kế toán và ngân hàng'),
  ('healthcare_calm', 'Healthcare Calm', 'Y tế và chăm sóc sức khỏe'),
  ('sales_impact', 'Sales Impact', 'Kinh doanh và bán hàng'),
  ('international_compact', 'International Compact', 'Gọn, chuẩn quốc tế'),
  ('premium_elegant_photo', 'Elegant Portrait', 'Mẫu Pro có ảnh chân dung'),
  ('premium_creative_portfolio', 'Creative Portfolio', 'Mẫu Pro cho portfolio sáng tạo'),
  ('premium_ai_focus', 'AI Focus', 'Mẫu Pro tối ưu cho vị trí AI/Data')
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  is_active = true;

commit;
