from pathlib import Path
import pypdfium2 as pdfium
import re,json
out=Path(__file__).parent
hits=[]
for path in Path('C:/enemR-project/cuestionarios').glob('*.pdf'):
    doc=pdfium.PdfDocument(str(path))
    texts=[]
    for i in range(len(doc)):
        page=doc[i]
        text=page.get_textpage().get_text_range()
        texts.append(f'\n=== PDF PAGE {i+1} ===\n'+text)
        if re.search('gobernando',text,re.I):
            page.render(scale=1.5).to_pil().save(out/f'{path.stem}-page-{i+1}.png')
            hits.append({'file':path.name,'page':i+1,'text':text})
    (out/(path.stem+'.pdfium.txt')).write_text('\n'.join(texts),encoding='utf-8')
(out/'questionnaire_pages.json').write_text(json.dumps(hits,ensure_ascii=False,indent=2),encoding='utf-8')
for h in hits:
    for match in re.finditer('gobernando',h['text'],re.I):
        print(h['file'],h['page'],repr(h['text'][max(0,match.start()-160):match.end()+550]))
