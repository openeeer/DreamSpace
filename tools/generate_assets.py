"""Resume-safe WaveSpeed generation. API key is read only from the environment."""
import concurrent.futures
import json
import os
from pathlib import Path
import re
import struct
import time
import urllib.request
import urllib.error

ROOT = Path(__file__).resolve().parents[1]
MODEL = 'openai/gpt-image-2.5-sunburst/text-to-image'
API = 'https://api.wavespeed.ai/api/v3'
KEY = os.environ.get('WAVESPEED_API_KEY', '')
JOBS = [(6, 'dreams/glass_staircase', '4:3'),
        (7, 'dreams/last_train', '4:3'),
        (8, 'dreams/sky_islands', '4:3'),
        (9, 'dreams/door_under_water', '4:3'),
        (10, 'backgrounds/nebula_foreground', '3:2'),
        (11, 'branding/app_icon', '1:1')]


def api(path, body=None):
    request = urllib.request.Request(API + path,
        data=None if body is None else json.dumps(body).encode(),
        headers={'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=90) as response:
        result = json.load(response)
    if result.get('code') != 200:
        raise RuntimeError(result.get('message', 'API request failed'))
    return result['data']


def generate(job):
    number, name, ratio = job
    target = ROOT / 'assets' / (name + '.png')
    receipt = ROOT / 'docs' / 'generation' / (name.split('/')[-1] + '.json')
    if target.exists():
        print(f'{name}: already downloaded', flush=True)
        return
    text = (ROOT / 'docs/ASSET_PROMPTS.md').read_text(encoding='utf-8')
    section = re.search(rf'^## {number}\. .*?\n(.*?)(?=^## |\Z)', text, re.M | re.S).group(1)
    prompt = re.search(r'^> (.+)$', section, re.M).group(1)
    if number <= 9:
        prompt += '\n' + re.search(r'^> (Premium cinematic.+)$', text, re.M).group(1)
    if number == 10:
        prompt = prompt.replace('panoramic 8:5', 'panoramic 3:2')
    body = {'prompt': prompt, 'resolution': '2k', 'quality': 'medium',
            'output_format': 'png', 'aspect_ratio': ratio}
    receipt.parent.mkdir(parents=True, exist_ok=True)
    if receipt.exists():
        record = json.loads(receipt.read_text(encoding='utf-8'))
        if record.get('status') == 'failed':
            raise RuntimeError(f'{name}: previous task failed; inspect receipt before resubmitting')
        task_id = record['task_id']
    else:
        # Never automatically retry a submission: a timeout may still incur a paid task.
        result = api('/' + MODEL, body)
        task_id = result['id']
        record = {'model': MODEL, 'task_id': task_id, 'request': body,
                  'status': result.get('status'), 'file': str(target.relative_to(ROOT))}
        receipt.write_text(json.dumps(record, indent=2, ensure_ascii=False), encoding='utf-8')
        print(f'{name}: submitted {task_id}', flush=True)
    deadline = time.monotonic() + 1500
    while time.monotonic() < deadline:
        try:
            result = api('/predictions/' + task_id + '/result')
        except (urllib.error.URLError, TimeoutError):
            time.sleep(10)
            continue
        status = result.get('status')
        if status in ('failed', 'cancelled'):
            record.update(status=status, error=result.get('error'))
            receipt.write_text(json.dumps(record, indent=2), encoding='utf-8')
            raise RuntimeError(f'{name}: {result.get("error", status)}')
        if status == 'completed':
            output = result['outputs'][0]
            # CDN requests deliberately do not receive the API Authorization header.
            with urllib.request.urlopen(output, timeout=120) as response:
                data = response.read()
            if data[:8] != b'\x89PNG\r\n\x1a\n':
                raise RuntimeError(f'{name}: output is not PNG')
            width, height = struct.unpack('>II', data[16:24])
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open('xb') as file:
                file.write(data)
            record.update(status=status, width=width, height=height, bytes=len(data))
            receipt.write_text(json.dumps(record, indent=2, ensure_ascii=False), encoding='utf-8')
            print(f'{name}: downloaded {width}x{height}, {len(data)} bytes', flush=True)
            return
        time.sleep(10)
    raise TimeoutError(f'{name}: still processing; rerun to resume task {task_id}')


if __name__ == '__main__':
    if not KEY:
        raise SystemExit('Set WAVESPEED_API_KEY in the process environment.')
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        futures = [pool.submit(generate, job) for job in JOBS]
        failures = []
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as error:
                failures.append(str(error))
                print(str(error), flush=True)
    if failures:
        raise SystemExit(1)
