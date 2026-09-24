-- Restaurant bios are public text shown on customer restaurant pages.
-- Only a signed-in Megjet admin can change them through the RPC.
alter table public.vendors
  add column if not exists bio text;

alter table public.vendors
  add constraint vendors_bio_length_check
  check (bio is null or char_length(bio) <= 600);

create or replace function public.admin_set_vendor_bio(p_vendor_id uuid, p_bio text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
  perform public.megjet_require_admin();
  if p_vendor_id is null or not exists (select 1 from public.vendors where id = p_vendor_id) then
    raise exception 'Vendor not found';
  end if;
  if p_bio is null or char_length(btrim(p_bio)) > 600 then
    raise exception 'Restaurant bio must be at most 600 characters';
  end if;
  update public.vendors set bio = btrim(p_bio) where id = p_vendor_id;
end;
$function$;

revoke all on function public.admin_set_vendor_bio(uuid,text) from public, anon;
grant execute on function public.admin_set_vendor_bio(uuid,text) to authenticated;
