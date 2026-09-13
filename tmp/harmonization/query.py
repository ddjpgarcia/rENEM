import json,re,sys
from pathlib import Path
r=json.loads((Path(__file__).parent/'metadata.json').read_text(encoding='utf8'))
pattern=sys.argv[1]
for x in r:
 if re.search(pattern,x['label']+' '+x['var'],re.I) and not re.search(r'\d{4}[abc]?$',x['var']):
  print(x['year'],x['var'],x['label'],json.dumps(x['codes'],ensure_ascii=False) if '--codes' in sys.argv else '')
