import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { test } from 'node:test';
import { createPlaybackUrl } from './sign-url.mjs';

const secret = '0123456789abcdef'.repeat(4);
const options = { baseUrl: 'wss://rtc.nbmedia.live:443/live/ch1', secret, nowMs: 1800000000000, ttlSeconds: 60 };

test('admission and active playback share an absolute expiry in milliseconds', () => {
    const signed = createPlaybackUrl(options);
    const url = new URL(signed);
    const policy = JSON.parse(Buffer.from(url.searchParams.get('policy'), 'base64url'));
    assert.deepEqual(policy, { url_expire: 1800000060000, stream_expire: 1800000060000 });
    assert.ok(signed.startsWith('wss://rtc.nbmedia.live:443/live/ch1?policy='));
    assert.match(url.searchParams.get('signature'), /^[A-Za-z0-9_-]+$/);
});

test('signature binds the entire explicit-port URL and policy; another stream cannot reuse it', () => {
    const signed = createPlaybackUrl(options);
    const [unsigned, signature] = signed.split('&signature=');
    assert.equal(createHmac('sha1', secret).update(unsigned).digest('base64url'), signature);
    for (const modified of [unsigned.replace('/ch1?', '/ch2?'), unsigned.replace(':443/', '/'), unsigned + 'x']) {
        assert.notEqual(createHmac('sha1', secret).update(modified).digest('base64url'), signature);
    }
});

test('unsafe URL inputs and URLs missing explicit ports are rejected', () => {
    for (const baseUrl of [
        'wss://rtc.nbmedia.live/live/ch1',
        'ws://rtc.nbmedia.live:443/live/ch1',
        'wss://user:pass@rtc.nbmedia.live:443/live/ch1',
        'wss://rtc.nbmedia.live:443/live/ch1?token=old',
        'wss://rtc.nbmedia.live:443/live/ch1#fragment',
        'wss://rtc.nbmedia.live:443/live/ch1/subfolder',
    ]) assert.throws(() => createPlaybackUrl({ ...options, baseUrl }));
});

test('unsafe lifetimes and placeholder secrets are rejected', () => {
    for (const ttlSeconds of [0, -1, 0.5, NaN, Infinity, 86401]) {
        assert.throws(() => createPlaybackUrl({ ...options, ttlSeconds }));
    }
    assert.throws(() => createPlaybackUrl({ ...options, nowMs: Number.MAX_SAFE_INTEGER }));
    assert.throws(() => createPlaybackUrl({ ...options, secret: 'REPLACE_WITH_64_RANDOM_HEX_CHARACTERS' }));
});
