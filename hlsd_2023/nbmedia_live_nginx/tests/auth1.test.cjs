const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

// Exercise the njs handlers with request doubles; this is not an nginx runtime test.
const source = fs.readFileSync(path.join(__dirname, '..', 'auth1.js'), 'utf8')
    .replace(/^const SECRET = .*;$/m, 'const SECRET = "test-secret";')
    .replace('const DEBUG = false;', 'const DEBUG = true;')
    .replace(/^export default (.*);$/m, 'globalThis.auth = $1;');
const now = 1800000000000;
const context = { require, Date: { now: () => now } };
vm.createContext(context);
vm.runInContext(source, context);
const auth = context.auth;
const expires = String(now + 60000);

function sign(company = 'companyA', stream = 'streamA', expiry = expires) {
    return crypto.createHmac('sha256', 'test-secret')
        .update(`${company}/${stream}:${expiry}`).digest('hex');
}

const token = sign();
const query = `expires=${expires}&token=${token}`;

function request(rawPath = '/hls/companyA/streamA/index.m3u8', args = query) {
    // Model the normalized location captures saved before the proxy rewrite.
    const normalized = path.posix.normalize(decodeURIComponent(rawPath));
    const match = /^\/(?:hls|webrtc)\/([^/]+)\/([^/]+)(?:\/|$)/.exec(normalized);
    return {
        variables: {
            request_uri: `${rawPath}?${args}`,
            auth_company: match && match[1],
            auth_stream: match && match[2],
            auth_query: args,
            args: '', // Proxy arguments may already have been stripped.
            uri: '/_verify_token',
        },
        errors: [],
        error(message) { this.errors.push(message); },
        return(status) { this.authStatus = status; },
    };
}

test('valid HLS and WebRTC requests retain the existing HMAC format', () => {
    for (const url of ['/hls/companyA/streamA/index.m3u8', '/hls/companyA/streamA/1.ts', '/webrtc/companyA/streamA']) {
        const r = request(url);
        auth.verifyToken(r);
        assert.equal(r.authStatus, 204);
        assert.ok(r.errors.length > 0);
        assert.ok(r.errors.every(message => !message.includes(token) && !message.includes(query)));
    }
});

test('raw and encoded traversal cannot reuse a different stream token', () => {
    for (const prefix of ['hls', 'webrtc']) {
        for (const traversal of ['../..', '%2e%2e/%2e%2e']) {
            const url = `/${prefix}/companyA/streamA/${traversal}/companyB/streamB` +
                (prefix === 'hls' ? '/index.m3u8' : '');
            const r = request(url);
            auth.verifyToken(r);
            assert.equal(r.authStatus, 401, url);
            r.variables.auth_query = `expires=${expires}&token=${sign('companyB', 'streamB')}`;
            auth.verifyToken(r);
            assert.equal(r.authStatus, 204, 'The routed stream identity is authoritative');
        }
    }
});

test('percent-encoded routing names authenticate against their decoded identity', () => {
    const r = request('/hls/%63ompanyA/streamA/index.m3u8');
    auth.verifyToken(r);
    assert.equal(r.authStatus, 204);
});

test('missing, invalid, expired and tampered credentials fail closed', () => {
    const cases = [
        ['', 403],
        [`expires=${expires}`, 403],
        [`token=${token}`, 403],
        [`expires=${expires}&token=${'z'.repeat(64)}`, 403],
        [`expires=${expires}&token=${'0'.repeat(64)}`, 401],
        [`expires=${now - 1}&token=${sign('companyA', 'streamA', now - 1)}`, 401],
    ];
    for (const [args, status] of cases) {
        const r = request(undefined, args);
        auth.verifyToken(r);
        assert.equal(r.authStatus, status);
    }
    const missingIdentity = request();
    delete missingIdentity.variables.auth_company;
    auth.verifyToken(missingIdentity);
    assert.equal(missingIdentity.authStatus, 403);
});

test('expiry must be a canonical positive safe integer in milliseconds', () => {
    for (const expiry of [`${expires}junk`, `0${expires}`, `+${expires}`, '1e20', 'Infinity', '9007199254740992', '-1', '0', '1.5']) {
        const r = request(undefined, `expires=${expiry}&token=${token}`);
        auth.verifyToken(r);
        assert.equal(r.authStatus, 403, expiry);
    }
});

test('malformed escaping and duplicate auth parameters produce controlled denials', () => {
    for (const extra of ['bad=%ZZ', 'bad=%E0%A4', '%ZZ=x', `token=${token}`, `TOKEN=${token}`, `to%6ben=${token}`, `expires=${expires}`, 'expires', 'token']) {
        const r = request(undefined, `${query}&${extra}`);
        assert.doesNotThrow(() => auth.verifyToken(r));
        assert.equal(r.authStatus, 403, extra);
        assert.equal(auth.upstreamArgs(r), '');
    }
});

test('origin arguments retain their original encoding but contain no auth parameters', () => {
    const r = request(undefined, `quality=high&To%6Ben=${token}&flag&EXPIRES=${expires}&label=a+b%26c&quality=low`);
    auth.verifyToken(r);
    assert.equal(r.authStatus, 204);
    assert.equal(auth.upstreamArgs(r), 'quality=high&flag&label=a+b%26c&quality=low');
    assert.equal(auth.upstreamArgs(request()), '');
});

test('playlist rewriting uses the same decoded credentials after proxy args are stripped', () => {
    const encodedToken = `%${token.charCodeAt(0).toString(16)}${token.slice(1)}`;
    const r = request(undefined, `EXPIRES=${expires}&to%6ben=${encodedToken}`);
    auth.verifyToken(r);
    assert.equal(r.authStatus, 204);
    r.status = 200;
    const buffers = [];
    r.sendBuffer = (data, flags) => buffers.push({ data, flags });
    auth.rewritePlaylist(r, '#EXTM3U\nseg', { last: false });
    assert.equal(buffers.length, 0);
    auth.rewritePlaylist(r, 'ment.ts\nother.ts?quality=high\n', { last: true });
    assert.equal(buffers[0].data,
        `#EXTM3U\nsegment.ts?expires=${expires}&token=${token}\nother.ts?quality=high&expires=${expires}&token=${token}\n`);
    assert.equal(buffers[0].flags.last, true);
    assert.equal(r.playlistBuffer, undefined);
});

test('error bodies pass through and rewritten responses clear Content-Length', () => {
    const r = request();
    r.status = 404;
    r.headersOut = { 'Content-Length': '9', 'Content-Type': 'text/plain' };
    const buffers = [];
    r.sendBuffer = (data, flags) => buffers.push({ data, flags });
    auth.rewritePlaylist(r, 'not found', { last: true });
    assert.equal(buffers[0].data, 'not found');
    auth.clearContentLength(r);
    assert.equal(r.headersOut['Content-Length'], undefined);
    assert.equal(r.headersOut['Content-Type'], 'text/plain');
});
