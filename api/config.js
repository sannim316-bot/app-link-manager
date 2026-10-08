export default function handler(req,res) {
  res.setHeader('Cache-Control','no-store');
  if(req.method !== 'GET') return res.status(405).end();
  const {SUPABASE_URL:url,SUPABASE_ANON_KEY:key}=process.env;
  if(!url||!key) return res.status(503).json({error:'Set the Supabase environment variables first.'});
  // Public anon key only. Never configure a service_role or secret key here.
  res.status(200).json({url,key});
}
