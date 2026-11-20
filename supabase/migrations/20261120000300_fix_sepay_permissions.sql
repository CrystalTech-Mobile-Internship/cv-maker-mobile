-- Grants service_role permissions on Pro upgrade tables so that
-- the sepay-webhook Edge Function can read pending requests, approve them,
-- and update payment references.

grant all on table public.pro_upgrade_requests to service_role;
grant all on table public.user_entitlements to service_role;
grant all on table public.payment_events to service_role;
