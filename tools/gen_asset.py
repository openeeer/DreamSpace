"""Generate DreamSpace artwork assets via the OpenRouter image API."""
import os, sys, json, base64, urllib.request, time

CFG = {}
with open('.env', encoding='utf-8') as f:
    for line in f:
        if '=' in line:
            k, v = line.strip().split('=', 1)
            CFG[k] = v
KEY, MODEL = CFG['OPENROUTER_API_KEY'], CFG['OPENROUTER_IMAGE_MODEL']

def generate(prompt: str, out_path: str, size: str = '1024x1024') -> bool:
    req = urllib.request.Request(
        'https://openrouter.ai/api/v1/images/generations',
        data=json.dumps({'model': MODEL, 'prompt': prompt, 'size': size}).encode(),
        headers={'Authorization': f'Bearer {KEY}', 'Content-Type': 'application/json'},
    )
    try:
        with urllib.request.urlopen(req, timeout=240) as r:
            body = json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        print(f'FAIL {out_path}: HTTP {e.code} {e.read().decode()[:300]}')
        return False
    except Exception as e:
        print(f'FAIL {out_path}: {e}')
        return False
    data = (body.get('data') or [{}])[0]
    b64 = data.get('b64_json')
    if not b64:
        print(f'FAIL {out_path}: no image data ({str(body)[:300]})')
        return False
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'wb') as f:
        f.write(base64.b64decode(b64))
    print(f'OK   {out_path} ({os.path.getsize(out_path)//1024} KB)')
    return True

if __name__ == '__main__':
    prompt, out = sys.argv[1], sys.argv[2]
    size = sys.argv[3] if len(sys.argv) > 3 else '1024x1024'
    sys.exit(0 if generate(prompt, out, size) else 1)
