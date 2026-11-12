import { createHmac } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

// Call only on your trusted backend, after authorizing the user for this stream.
export function createPlaybackUrl({ baseUrl, secret, ttlSeconds = 300, nowMs = Date.now() }) {
    const parsed = new URL(baseUrl);
    const authority = /^wss:\/\/([^/]+)\//.exec(baseUrl);
    const portMatch = authority && /:([0-9]+)$/.exec(authority[1]);
    if (parsed.protocol !== 'wss:' || !portMatch || parsed.username || parsed.password ||
        parsed.search || parsed.hash || !/^\/[A-Za-z0-9_-]+\/[A-Za-z0-9_-]+$/.test(parsed.pathname)) {
        throw new Error('Use wss://host:port/app/stream with an explicit port and no query or fragment');
    }
    if (typeof secret !== 'string' || !/^[0-9a-fA-F]{64}$/.test(secret)) {
        throw new Error('The signing secret must be 64 random hexadecimal characters');
    }
    if (!Number.isSafeInteger(ttlSeconds) || ttlSeconds < 1 || ttlSeconds > 86400 ||
        !Number.isSafeInteger(nowMs) || nowMs < 0 ||
        !Number.isSafeInteger(nowMs + ttlSeconds * 1000)) {
        throw new Error('TTL must be a whole number from 1 to 86400 seconds and time must be valid');
    }

    const expiry = nowMs + ttlSeconds * 1000;
    const policy = Buffer.from(JSON.stringify({ url_expire: expiry, stream_expire: expiry })).toString('base64url');
    // URL serialization normally removes :443. OME's signature requires it.
    const unsigned = `wss://${parsed.hostname}:${Number(portMatch[1])}${parsed.pathname}?policy=${policy}`;
    const signature = createHmac('sha1', secret).update(unsigned).digest('base64url');
    return `${unsigned}&signature=${signature}`;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
    try {
        const baseUrl = process.argv[2];
        const ttlSeconds = Number(process.argv[3] || 300);
        if (!baseUrl) throw new Error('Usage: node sign-url.mjs wss://host:443/live/ch1 [ttl-seconds]');
        let secret = process.env.OME_SIGNING_SECRET;
        if (!secret) {
            // Read only this one value; never execute .env as shell code.
            const env = readFileSync(new URL('.env', import.meta.url), 'utf8');
            const match = /^OME_SIGNING_SECRET=([0-9a-fA-F]{64})\r?$/m.exec(env);
            if (!match) throw new Error('Set OME_SIGNING_SECRET in the environment or in ome/.env');
            secret = match[1];
        }
        console.log(createPlaybackUrl({ baseUrl, secret, ttlSeconds }));
    } catch (error) {
        console.error(error.message);
        process.exitCode = 1;
    }
}
