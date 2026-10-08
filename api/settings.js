export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Vercel-CDN-Cache-Control', 'no-store');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'GET') return res.status(405).json({error:'Method not allowed'});
  const {SUPABASE_URL:url, SUPABASE_ANON_KEY:key} = process.env;
  if (!url || !key) return res.status(503).json({error:'Service not configured'});
  const app = req.query.app;
  if (typeof app !== 'string' || !/^[a-z0-9-]{1,64}$/.test(app)) return res.status(400).json({error:'Invalid app ID'});
  try {
    const response = await fetch(`${url}/rest/v1/app_links?app_id=eq.${encodeURIComponent(app)}&select=app_id,links,revision,updated_at`, {
      headers:{apikey:key, Authorization:`Bearer ${key}`}, signal:AbortSignal.timeout(8000), cache:'no-store'
    });
    if (!response.ok) throw new Error('Database unavailable');
    const rows = await response.json();
    if (!rows.length) return res.status(404).json({error:'App not found'});
    return res.status(200).json(rows[0]);
  } catch { return res.status(503).json({error:'Settings temporarily unavailable'}); }
}
