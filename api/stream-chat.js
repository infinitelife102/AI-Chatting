const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';
const MODEL = 'llama-3.3-70b-versatile';

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => { data += chunk; });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

export default async function handler(req, res) {
  // CORS: allow web app origin
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'GROQ_API_KEY not configured' });
  }

  const raw = await readBody(req);
  let body;
  try {
    body = typeof raw === 'string' ? JSON.parse(raw || '{}') : raw;
  } catch (_) {
    return res.status(400).json({ error: 'Invalid JSON body' });
  }
  const messages = body?.messages;
  if (!Array.isArray(messages)) {
    return res.status(400).json({ error: 'Missing or invalid "messages" array' });
  }

  try {
    const response = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: MODEL,
        messages,
        stream: true,
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      return res.status(response.status).send(text);
    }

    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders?.();

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';
      for (const line of lines) {
        res.write(line + '\n');
      }
      if (typeof res.flush === 'function') res.flush();
    }
    if (buffer) res.write(buffer);
    res.end();
  } catch (err) {
    console.error('stream-chat error:', err);
    return res.status(500).json({ error: 'Proxy error', message: err.message });
  }
}
