const crypto = require('crypto');

const SECRET = "redacted";
const DEBUG = false;

function parseQueryString(qs) {
    const result = { token: '', expires: '', upstreamArgs: '' };
    const seen = {};
    const upstream = [];
    if (!qs) return result;
    const pairs = qs.split('&');
    for (let i = 0; i < pairs.length; i++) {
        const idx = pairs[i].indexOf('=');
        const key = decodeURIComponent((idx === -1 ? pairs[i] : pairs[i].substring(0, idx)).replace(/\+/g, ' '));
        const value = decodeURIComponent((idx === -1 ? '' : pairs[i].substring(idx + 1)).replace(/\+/g, ' '));
        const authKey = key.toLowerCase();
        if (authKey === 'token' || authKey === 'expires') {
            if (seen[authKey]) throw new Error('Duplicate authentication parameter');
            seen[authKey] = true;
            result[authKey] = value;
        } else {
            // Preserve unrelated origin parameters exactly as supplied.
            upstream.push(pairs[i]);
        }
    }
    result.upstreamArgs = upstream.join('&');
    return result;
}

function upstreamArgs(r) {
    try {
        return parseQueryString(r.variables.auth_query).upstreamArgs;
    } catch (e) {
        // verifyToken will reject malformed queries before proxying.
        return '';
    }
}

function verifyToken(r) {
    function log(msg) { if (DEBUG) r.error(msg); }

    // Saved by the parent location from nginx's normalized routing captures,
    // before rewrites change the URI or remove the authentication arguments.
    const company = r.variables.auth_company;
    const stream = r.variables.auth_stream;
    let params;
    try {
        params = parseQueryString(r.variables.auth_query);
    } catch (e) {
        log('auth debug: malformed or duplicate query parameter');
        r.return(403);
        return;
    }
    const expires = Number(params.expires);
    const token = params.token;

    log(`auth debug: company=${company} stream=${stream} expires=${expires} tokenLen=${token.length}`);

    if (!company || !stream || !/^[1-9][0-9]*$/.test(params.expires) ||
        !Number.isSafeInteger(expires) || !/^[0-9a-f]{64}$/.test(token)) {
        log('auth debug: failed parameter validation');
        r.return(403);
        return;
    }

    const now = Date.now(); // ms, matches token generator
    if (now > expires) {
        log(`auth debug: expired now=${now} expires=${expires}`);
        r.return(401);
        return;
    }

    const authStr = `${company}/${stream}:${expires}`;
    const expected = crypto.createHmac('sha256', SECRET).update(authStr).digest('hex');

    let ok = true;
    for (let i = 0; i < expected.length; i++) {
        if (expected[i] !== token[i]) ok = false;
    }

    log(`auth debug: match=${ok}`);
    r.return(ok ? 204 : 401);
}

function rewritePlaylist(r, data, flags) {
    if (r.status !== 200) {
        r.sendBuffer(data, flags);
        return;
    }

    r.playlistBuffer = (r.playlistBuffer || '') + data;

    if (!flags.last) {
        return;
    }

    const params = parseQueryString(r.variables.auth_query);
    const token = params.token;
    const expires = params.expires;
    const suffix = `?expires=${expires}&token=${token}`;

    const lines = r.playlistBuffer.split('\n');
    const rewritten = lines.map(function (line) {
        const trimmed = line.trim();
        if (trimmed === '' || trimmed.startsWith('#')) {
            return line;
        }
        if (trimmed.indexOf('?') === -1) {
            return trimmed + suffix;
        }
        return trimmed + '&' + suffix.substring(1);
    });

    r.sendBuffer(rewritten.join('\n'), flags);
    delete r.playlistBuffer;
}

function clearContentLength(r) {
    delete r.headersOut['Content-Length'];
}

export default { verifyToken, rewritePlaylist, clearContentLength, upstreamArgs };
