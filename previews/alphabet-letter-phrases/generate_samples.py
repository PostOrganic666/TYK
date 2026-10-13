from pathlib import Path
import importlib.util, re, json, concurrent.futures
workspace=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('speech',workspace/'ToddlerLock/tools/generate_speech.py')
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
key=re.search(r'sk-or-v1-[A-Za-z0-9_-]+',(workspace/'Key.txt').read_text()).group()
root=Path(__file__).resolve().parent
items=[{'id':'sample-a','glyph':'А','text':'А. Буква А.'},{'id':'sample-m','glyph':'М','text':'Эм. Буква эм.'},{'id':'sample-t','glyph':'Т','text':'Тэ. Буква тэ.'},{'id':'sample-sh','glyph':'Ш','text':'Ша. Буква ша.'}]
def run(item):
 e=m.generate(item,root,key)
 old=root/'ToddlerLock'/e['file']; new=root/(item['id']+'.wav'); old.replace(new); e['file']=new.name
 print(item['glyph']+': '+str(e['durationSeconds'])+' s',flush=True)
 return e
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
 entries=list(pool.map(run,items))
(root/'samples.json').write_text(json.dumps({'model':m.MODEL,'voice':m.VOICE,'entries':entries},ensure_ascii=False,indent=2)+'\n')
(root/'ToddlerLock/Resources/Speech').rmdir(); (root/'ToddlerLock/Resources').rmdir(); (root/'ToddlerLock').rmdir()
