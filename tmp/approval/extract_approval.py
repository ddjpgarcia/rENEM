from pathlib import Path
import json,re
import pandas as pd
from pypdf import PdfReader

out=Path(__file__).parent
mapping={1997:'p23',2000:'pacu',2003:'p28',2006:'p46',2009:'pacu',2012:'p42',2015:'p48',2018:'p15',2021:'P2',2024:'P2'}
records=[]
for year,var in mapping.items():
    path=Path(f'C:/enemR-project/datos_stata/ENEM_{year}_isco08.dta')
    reader=pd.io.stata.StataReader(path,convert_categoricals=False)
    labels=reader.variable_labels(); values=reader.value_labels()
    names=reader.varlist if hasattr(reader,'varlist') else reader._varlist
    sets=reader.lbllist if hasattr(reader,'lbllist') else reader._lbllist
    lookup=dict(zip(names,sets))
    cols=[var,f'approval{year}a',f'approval{year}b']
    df=pd.read_stata(path,columns=cols,convert_categoricals=False)
    rec={'year':year,'variables':{c:{'label':labels[c],'value_labels':{str(k):v for k,v in values.get(lookup[c],{}).items()},'counts':{str(k):int(v) for k,v in df[c].value_counts(dropna=False).sort_index().items()}} for c in cols},'recodes':df.groupby(cols,dropna=False).size().reset_index(name='n').to_dict('records')}
    records.append(rec)
(out/'stata_evidence.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
for path in Path('C:/enemR-project/cuestionarios').glob('*.pdf'):
    reader=PdfReader(path)
    pages=[f'\n=== PDF PAGE {i+1} ===\n'+(p.extract_text(extraction_mode='layout') or '') for i,p in enumerate(reader.pages)]
    (out/(path.stem+'.txt')).write_text('\n'.join(pages),encoding='utf-8')
print(json.dumps(records,ensure_ascii=False,indent=2))

