from pathlib import Path
import pandas as pd,json,re
out=Path(__file__).parent
def clean(s):
    for _ in range(3):
        if not any(c in s for c in ['Ã','Â','\x83','\x82']): break
        try:s=s.encode('latin1').decode('utf8')
        except (UnicodeEncodeError,UnicodeDecodeError):break
    return s
records=[]
for path in Path('C:/enemR-project/datos_stata').glob('*.dta'):
    year=int(re.search(r'\d{4}',path.name)[0])
    rd=pd.io.stata.StataReader(path,convert_categoricals=False)
    vl=rd.variable_labels(); labels=rd.value_labels(); labelsets=dict(zip(rd._varlist,rd._lbllist))
    df=pd.read_stata(path,convert_categoricals=False)
    for v in df:
        counts=df[v].value_counts(dropna=False)
        records.append(dict(year=year,var=v,label=clean(vl.get(v,'')),label_raw=vl.get(v,''),n=len(df),missing=int(df[v].isna().sum()),unique=int(df[v].nunique()),dtype=str(df[v].dtype),codes={str(k):clean(val) for k,val in labels.get(labelsets[v],{}).items()},counts={str(k):int(n) for k,n in counts.items()} if len(counts)<150 else {},source=path.name))
(out/'metadata.json').write_text(json.dumps(records,ensure_ascii=False),encoding='utf8')
for year in [1997,2024]:
    (out/f'inventory_{year}.txt').write_text('\n'.join(f"{r['var']}: {r['label']}" for r in records if r['year']==year),encoding='utf8')
print('Variables:',len(records))
sets=[set(r['var'] for r in records if r['year']==y) for y in sorted({r['year'] for r in records})]
print('Exact common names:',sorted(set.intersection(*sets)))
