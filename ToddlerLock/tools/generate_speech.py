#!/usr/bin/env python3
"""Generate only missing/stale offline Kore clips. API key is never bundled.
Run from repository root: python3 ToddlerLock/tools/generate_speech.py --key-file Key.txt
Use --check for an offline coverage check; no key or network is needed.
"""
from pathlib import Path
import argparse, array, concurrent.futures, hashlib, json, math, re, sys, time
import urllib.request, urllib.error, wave

MODEL = 'google/gemini-3.8-flash-tts'
VOICE = 'Kore'
RATE = 24000

def validate_alphabet(root, require_resources=False):
    path = root / 'catalog/alphabet.json'
    if not path.exists():
        return
    cards = json.loads(path.read_text())
    source = root / 'ToddlerLock/Modes'
    glyphs = re.findall(r'\.init\(glyph: "([^"]+)"', (source / 'RussianAlphabet.swift').read_text())
    if [card['glyph'] for card in cards] != glyphs:
        raise ValueError('Alphabet catalogue must contain all 33 letters in order')
    expected = []
    for card in cards:
        if len(card['pictures']) != 3 or len({p['name'] for p in card['pictures']}) != 3:
            raise ValueError('Each letter needs three distinct examples')
        for picture in card['pictures']:
            if card['glyph'].lower() not in picture['name'].lower():
                raise ValueError('Example does not contain its letter: ' + picture['name'])
            expected.append((picture['name'], picture['assetName']))
    runtime = re.findall(r'\.init\(name: "([^"]+)", assetName: "([^"]+)"\)',
                         (source / 'AlphabetCards.swift').read_text())
    if runtime != expected:
        raise ValueError('Alphabet catalogue and runtime examples differ')
    if require_resources:
        resources = root / 'ToddlerLock/Resources'
        paths = list((resources / 'Pictures').rglob('*.png')) + list((resources / 'Alphabet').glob('*.png'))
        files = {path.stem:path for path in paths}
        project = (root / 'ToddlerLock.xcodeproj/project.pbxproj').read_text()
        for _, asset in expected:
            if asset not in files:
                raise ValueError('Missing alphabet picture: ' + asset)
            if str(files[asset].relative_to(root / 'ToddlerLock')) not in project:
                raise ValueError('Unbundled alphabet picture: ' + asset)


def current_items(root):
    validate_alphabet(root)
    pictures = json.loads((root / 'catalog/pictures.json').read_text())
    source = root / 'ToddlerLock'
    runtime = re.findall(r'\.init\(name: "([^"]+)", assetName: "([^"]+)"\)', (source / 'Modes/PictureMode.swift').read_text())
    if sorted(runtime) != sorted((p['name'], p['asset']) for p in pictures):
        raise ValueError('Picture catalogue and runtime names differ')
    items = [{'id': p['asset'], 'kind': 'picture', 'text': p['name']} for p in pictures]
    letters = re.findall(r'\.init\(glyph: "([^"]+)", spokenName: "([^"]+)"\)', (source / 'Modes/RussianAlphabet.swift').read_text())
    items += [{'id': f'letter-{ord(glyph):04x}', 'kind': 'letter', 'glyph': glyph, 'text': text} for glyph, text in letters]
    # Reuse existing recordings for shared words, including repeated alphabet examples.
    alphabet_path = root / 'catalog/alphabet.json'
    known_texts = {item['text'] for item in items}
    if alphabet_path.exists():
        for card in json.loads(alphabet_path.read_text()):
            for picture in card['pictures']:
                text = picture['name']
                if text not in known_texts:
                    word_id = 'alphabet-word-' + hashlib.sha256(text.encode()).hexdigest()[:12]
                    items.append({'id': word_id, 'kind': 'alphabet-word', 'text': text})
                    known_texts.add(text)
    items += [{'id': 'voice-preview', 'kind': 'preview', 'text': 'Привет! Давай играть!'}]
    if len({i['id'] for i in items}) != len(items) or len({i['text'] for i in items}) != len(items):
        raise ValueError('Duplicate speech IDs or texts')
    return items

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def valid(item, entry, root):
    if not entry or any(item.get(k) != entry.get(k) for k in item): return False
    if entry.get('status') != 'generated' or entry.get('model') != MODEL or entry.get('voice') != VOICE: return False
    path = root / 'ToddlerLock' / entry['file']
    if not path.is_file() or digest(path) != entry.get('sha256'): return False
    try:
        with wave.open(str(path), 'rb') as wav:
            return wav.getframerate() == RATE and wav.getnchannels() == 1 and wav.getsampwidth() == 2 and wav.getnframes() > RATE * .15
    except (wave.Error, EOFError): return False

def trim_pcm(data):
    samples = array.array('h', data)
    if sys.byteorder != 'little': samples.byteswap()
    frame = 240
    rms = [math.sqrt(sum(s*s for s in samples[i:i+frame])/len(samples[i:i+frame])) for i in range(0,len(samples),frame)]
    # Retain quiet consonants and 80/140 ms of room before/after the detected speech.
    active = [i for i, value in enumerate(rms) if value >= 130]
    if not active: raise ValueError('Silent audio')
    start = max(0, active[0]*frame - 1920)
    end = min(len(samples), (active[-1]+1)*frame + 3360)
    clipped = samples[start:end]
    if len(clipped) < RATE*.15 or len(clipped) > RATE*15:
        raise ValueError('Unexpected clip duration')
    if sys.byteorder != 'little': clipped.byteswap()
    return clipped.tobytes(), {'leadingTrimSeconds':round(start/RATE,3),'trailingTrimSeconds':round((len(samples)-end)/RATE,3)}

def generate(item, root, key):
    payload = {'model': MODEL, 'voice': VOICE, 'input': item['text'] if item['text'].endswith('!') else item['text']+'.', 'response_format':'pcm'}
    for attempt in range(3):
        try:
            req = urllib.request.Request('https://openrouter.ai/api/v1/audio/speech', data=json.dumps(payload).encode(), headers={'Authorization':'Bearer '+key,'Content-Type':'application/json'})
            with urllib.request.urlopen(req,timeout=120) as response:
                mime = response.headers.get('Content-Type','')
                generation_id = response.headers.get('X-Generation-Id')
                data = response.read()
            if 'audio/pcm' not in mime or not data or len(data)%2: raise ValueError('Invalid PCM response')
            data, trim = trim_pcm(data)
            relative = f'Resources/Speech/{item["id"]}.wav'
            path = root / 'ToddlerLock' / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            temp = path.with_suffix('.partial')
            with wave.open(str(temp),'wb') as wav:
                wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(RATE); wav.writeframes(data)
            temp.replace(path)
            return dict(item,status='generated',model=MODEL,voice=VOICE,file=relative,sha256=digest(path),durationSeconds=round(len(data)/(RATE*2),3),generationId=generation_id,**trim)
        except urllib.error.HTTPError as error:
            # Error bodies can contain echoed headers: never print them.
            if error.code in (401,402,403): raise RuntimeError(f'OpenRouter HTTP {error.code}') from None
            if attempt == 2: raise RuntimeError(f'OpenRouter HTTP {error.code}') from None
        except (OSError,ValueError) as error:
            if attempt == 2: raise RuntimeError(type(error).__name__+': generation failed') from None
        time.sleep(2*(attempt+1))

def save_manifest(path, entries):
    temp = path.with_suffix('.partial')
    temp.write_text(json.dumps({'schemaVersion':1,'model':MODEL,'voice':VOICE,'language':'ru-RU','sampleRate':RATE,'entries':entries},ensure_ascii=False,indent=2)+'\n')
    temp.replace(path)

def check_bundle(root, items, done):
    validate_alphabet(root, require_resources=True)
    index_path = root / 'ToddlerLock/Resources/Speech/speech-index.json'
    expected = {i['text']:Path(done[i['id']]['file']).stem for i in items}
    if not index_path.exists() or json.loads(index_path.read_text()) != expected:
        raise ValueError('Runtime speech index is missing/stale; rerun generation')
    project = (root / 'ToddlerLock.xcodeproj/project.pbxproj').read_text()
    for entry in done.values():
        if entry['file'] not in project:
            raise ValueError('Unbundled speech resource: '+entry['file'])
    if 'Resources/Speech/speech-index.json' not in project:
        raise ValueError('Runtime speech index is not bundled')
    for picture in json.loads((root / 'catalog/pictures.json').read_text()):
        entry = done[picture['asset']]
        expected_speech = {'status':'generated', 'text':entry['text'],
                           'file':entry['file'], 'voice':VOICE}
        if picture.get('speech') != expected_speech:
            raise ValueError('Stale picture speech marker: '+picture['asset'])


def update_readable_catalog(root, items, done):
    path = root / 'catalog/README.md'
    text = path.read_text().split('\n## Озвучка Kore')[0]
    by_id = {i['id']:i for i in items}
    lines = []
    for line in text.splitlines():
        if line.startswith('| Название для озвучки |'):
            line = '| Название для озвучки | Файл | Статус | Озвучка |'
        elif line.startswith('| --- | --- | --- |'):
            line = '| --- | --- | --- | --- |'
        elif line.startswith('| ') and '.png]' in line:
            match = re.search(r'\[([^\]]+)\.png\]',line)
            if match and match.group(1) in by_id:
                entry = done[match.group(1)]
                cells = line.split('|')[1:4]
                link = '../ToddlerLock/'+entry['file']
                line = '|'+ '|'.join(cells) + f'| [Готово · Kore]({link}) |'
        lines.append(line)
    text = '\n'.join(lines).rstrip()+'\n'
    picture_count = sum(i["kind"] == "picture" for i in items)
    letter_count = sum(i["kind"] == "letter" for i in items)
    text += f"""
## Озвучка Kore

Полная процедура: [пайплайн генерации озвучки](SPEECH_PIPELINE.md).

Все {picture_count} картинок и {letter_count} буквы озвучены по отдельности женским голосом Kore
модели `google/gemini-3.8-flash-tts`; также записано «Привет! Давай играть!».
Слова нового режима «Алфавит» также записаны отдельно; общие названия используют прежние записи.
Записи хранятся в `../ToddlerLock/Resources/Speech/` и работают без сети.
Формат — WAV, PCM 24 кГц / 16 бит / моно; начальная и конечная тишина обрезаны.

[speech.json](speech.json) — полный каталог записей: ID, точный текст, голос,
модель, файл, длительность и SHA-256. У каждой картинки в
[pictures.json](pictures.json) есть поле `speech`; столбец «Озвучка» выше ведёт
к записи. Наличие старого файла с прежним названием не считается покрытием
изменённого текста.

После добавления элементов сначала обновить runtime и `pictures.json`, затем
из корня репозитория выполнить:

```sh
python3 ToddlerLock/tools/generate_speech.py --check
# Создать только недостающие/изменённые записи:
python3 ToddlerLock/tools/generate_speech.py --key-file Key.txt
python3 ToddlerLock/generate_project.py
python3 ToddlerLock/tools/generate_speech.py --check
```

Проверка выводит `MISSING` с ID и текстом для каждой недостающей записи;
сверяет файлы, контрольные суммы, runtime index и включение в Xcode resources.
Она выполняется и перед сборкой. Ключ нужен только при подготовке записей,
исключён из Git и не входит в приложение. До генерации новый элемент может
использовать системную офлайн-озвучку.

### Буквы

| Буква | Произносится | Озвучка |
| --- | --- | --- |
"""
    for i in items:
        if i['kind']=='letter':
            text += f"| {i['glyph']} | {i['text']} | [Готово · Kore](../ToddlerLock/{done[i['id']]['file']}) |\n"
    text += '\nПриветствие: [Готово · Kore](../ToddlerLock/Resources/Speech/voice-preview.wav).\n'
    path.write_text(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument('--key-file',type=Path)
    parser.add_argument('--workers',type=int,default=4)
    parser.add_argument('--check',action='store_true')
    args = parser.parse_args()
    root = args.root.resolve()
    items = current_items(root)
    manifest = root / 'catalog/speech.json'
    old = json.loads(manifest.read_text())['entries'] if manifest.exists() else []
    existing = {e['id']:e for e in old}
    done = {i['id']:existing[i['id']] for i in items if valid(i,existing.get(i['id']),root)}
    missing = [i for i in items if i['id'] not in done]
    print(f'Coverage: {len(done)}/{len(items)}; missing/stale: {len(missing)}',flush=True)
    if args.check:
        for i in missing: print(f'MISSING: {i["id"]} — {i["text"]}')
        if missing: return 1
        check_bundle(root, items, done)
        print('OK: files, hashes, catalogue markers and Xcode resources agree')
        return 0
    if missing:
        if not args.key_file: parser.error('--key-file is required for generation')
        match = re.search(r'sk-or-v1-[A-Za-z0-9_-]+',args.key_file.read_text())
        if not match: parser.error('No OpenRouter API key in the supplied file')
        failures = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=max(1,min(args.workers,8))) as pool:
            futures = {pool.submit(generate,i,root,match.group()):i for i in missing}
            for future in concurrent.futures.as_completed(futures):
                item = futures[future]
                try:
                    entry = future.result(); done[item['id']] = entry
                    save_manifest(manifest,[done[i['id']] for i in items if i['id'] in done])
                    print(f'{len(done)}/{len(items)} {item["id"]}: {entry["durationSeconds"]}s',flush=True)
                except Exception as error:
                    failures.append(item['id']); print(f'FAILED {item["id"]}: {error}',flush=True)
        if failures: print(f'Incomplete: {len(failures)} failures; rerun to resume'); return 1
    save_manifest(manifest,[done[i['id']] for i in items])
    # Runtime lookup is separate from the provenance catalogue.
    runtime = {i['text']:Path(done[i['id']]['file']).stem for i in items}
    (root/'ToddlerLock/Resources/Speech/speech-index.json').write_text(json.dumps(runtime,ensure_ascii=False,indent=2)+'\n')
    pictures_path = root/'catalog/pictures.json'
    pictures = json.loads(pictures_path.read_text())
    for picture in pictures:
        e = done[picture['asset']]
        picture['speech'] = {'status':e['status'],'text':e['text'],'file':e['file'],'voice':VOICE}
    pictures_path.write_text(json.dumps(pictures,ensure_ascii=False,indent=2)+'\n')
    update_readable_catalog(root, items, done)
    print('Complete: catalogue and runtime index updated',flush=True)
    return 0

if __name__ == '__main__': raise SystemExit(main())
