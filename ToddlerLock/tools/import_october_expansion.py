#!/usr/bin/env python3
"""Normalize October 2026 imagegen sprites and render labelled review sheets."""
import hashlib,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
EXPANSION=ROOT/'catalog/expansion-2026-10'
def main():
 items=json.loads((EXPANSION/'items.json').read_text())
 sloth=dict(asset='animal-sloth',name='ленивец',group='animals',status='replaced',prompt="Use case: illustration-story. One friendly anatomically correct brown three-toed sloth sitting, full body with exactly four limbs, two short bent back legs and two long front arms resting naturally, three curved claws on each visible paw. Cream face with brown eye patches, small dark nose, gentle expression. Warm hand-painted watercolor and gouache children's picture-book style, textured fur, muted natural colors. Centered in square image, fully visible with generous transparent padding 15% each side. Genuinely transparent background. No branch, scenery, text, watermark, extra limbs or fused limbs.")
 available=[]
 for item in items+[sloth]:
  source=EXPANSION/'originals'/(item['asset']+'.png')
  if not source.exists():continue
  folder='Animals' if item['group']=='animals' else 'Household'
  with Image.open(source) as image:
   image=image.convert('RGBA')
   assert image.getchannel('A').getextrema()[0]==0,source
   bbox=image.getchannel('A').point(lambda a:255 if a>=16 else 0).getbbox()
   assert bbox,source
   image=image.crop(bbox)
   scale=440/max(image.size)
   image=image.resize((round(image.width*scale),round(image.height*scale)),Image.Resampling.LANCZOS)
   sprite=Image.new('RGBA',(512,512))
   sprite.alpha_composite(image,((512-image.width)//2,(512-image.height)//2))
   dest=ROOT/'ToddlerLock/Resources/Pictures'/folder/(item['asset']+'.png')
   sprite.save(dest,optimize=True)
  item['sourceFile']='originals/'+source.name
  item['sourceSha256']=hashlib.sha256(source.read_bytes()).hexdigest()
  item['file']=str(dest.relative_to(ROOT/'ToddlerLock'))
  available.append(item)
 font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',18)
 for category in ['animals','household']:
  selected=[i for i in available if (i['group']=='animals')==(category=='animals')]
  if not selected:continue
  page=Image.new('RGB',(1200,245*((len(selected)+4)//5)),'#faf2e0')
  draw=ImageDraw.Draw(page)
  for index,item in enumerate(selected):
   x,y=index%5*240,index//5*245
   with Image.open(ROOT/'ToddlerLock'/item['file']) as im:
    im=im.resize((210,210),Image.Resampling.LANCZOS)
    page.paste(im,(x+15,y+1),im)
   draw.text((x+120,y+224),item['name'],font=font,fill='#443b32',anchor='mm')
  page.save(EXPANSION/(category+'-preview.jpg'),quality=93)
 (EXPANSION/'generation.json').write_text(json.dumps({'generator':'built-in image_gen','items':available},ensure_ascii=False,indent=2)+'\n')
 print('Imported',len(available),'of 101 requested illustrations')
if __name__=='__main__':main()
