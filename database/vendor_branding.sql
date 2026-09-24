-- Vendor artwork is stored in Supabase Storage and referenced by public URL.
alter table public.vendors add column if not exists logo_url text;
alter table public.vendors add column if not exists banner_url text;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('vendor-images','vendor-images',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists "Megjet admins upload vendor images" on storage.objects;
create policy "Megjet admins upload vendor images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'vendor-images'
  and exists (select 1 from public.admin_users a where a.user_id = (select auth.uid()))
  and exists (select 1 from public.vendors v where v.id::text = split_part(objects.name, '/', 1))
  and split_part(objects.name, '/', 2) in ('logo','banner')
  and length(split_part(objects.name, '/', 3)) > 0
);

create or replace function public.admin_set_vendor_branding(
  p_vendor_id uuid,
  p_logo_url text default null,
  p_banner_url text default null,
  p_clear_logo boolean default false,
  p_clear_banner boolean default false
) returns void language plpgsql security definer set search_path = '' as $function$
declare
  v_prefix text := 'https://manuspenfcahagcstedd.supabase.co/storage/v1/object/public/vendor-images/' || p_vendor_id::text || '/';
begin
  perform public.megjet_require_admin();
  if p_vendor_id is null or not exists (select 1 from public.vendors where id = p_vendor_id) then
    raise exception 'Vendor not found';
  end if;
  if p_logo_url is not null and (
    not starts_with(p_logo_url, v_prefix || 'logo/') or length(p_logo_url) > 1000
  ) then raise exception 'Invalid vendor logo URL'; end if;
  if p_banner_url is not null and (
    not starts_with(p_banner_url, v_prefix || 'banner/') or length(p_banner_url) > 1000
  ) then raise exception 'Invalid vendor banner URL'; end if;
  update public.vendors set
    logo_url = case when p_clear_logo then null else coalesce(p_logo_url,logo_url) end,
    banner_url = case when p_clear_banner then null else coalesce(p_banner_url,banner_url) end
  where id = p_vendor_id;
end;
$function$;

revoke all on function public.admin_set_vendor_branding(uuid,text,text,boolean,boolean) from public, anon;
grant execute on function public.admin_set_vendor_branding(uuid,text,text,boolean,boolean) to authenticated;
