from candidates import *
import math,collections
primary={1997:'1997',2000:'2000',2003:'2003 conalianza',2006:'2006 Version 1',2009:'2009 Version 1',2012:'2012',2015:'2015 Version 1 Publicidad',2018:'2018 CSES',2021:'2021 Version 1 Erosion Democratica',2024:'2024 Version 1, 2 y 3'}
PDF={}
def norm(s):
 return re.sub(r'\s+',' ',''.join(c for c in unicodedata.normalize('NFD',s.lower()) if unicodedata.category(c)!='Mn')).strip()
for y,stem in primary.items():
 text=(BASE.parent/'approval'/f'{stem}.pdfium.txt').read_text(encoding='utf8')
 PDF[y]=[(int(a),b) for a,b in re.findall(r'=== PDF PAGE (\d+) ===\s*(.*?)(?==== PDF PAGE|\Z)',text,re.S)]

def locate(y,v,label):
 # Exact questionnaire anchors; excerpts retain the original wording, with whitespace normalized.
 # Numbered subitems refer to their whole battery, whose row determines the selected variable.
 anchor=None
 m=re.fullmatch(r'(p|ps|s|se)(\d+)(.*)',v,re.I)
 if m:
  prefix='S' if m[1].lower() in ['s','se','ps'] else 'P'
  number=m[2]; anchor=(prefix,number)
 if y in [1997,2000] and v in ['sex','edad','escol']:
  anchor=('S',{'sex':'1','edad':'2','escol':'3'}[v])
 if v in ['EDAD','Edad']:anchor=('S','1')
 if y==2000 and v=='pacu':anchor=('P','67')
 if y==2009 and v=='pacu':anchor=('A','ACU')
 candidates=[]
 if anchor:
  p,n=anchor
  pat=(rf'(?im)^\s*(?:P\s*)?{n}(?!\d)[.\-\s]+(?=[^\r\n]*[A-Za-zÁÉÍÓÚ¿])' if p=='P' else rf'(?im)^\s*S\s*{n}(?!\d)[.\-\s]+' if p=='S' else r'(?im)^\s*ACU\.')
  for page,txt in PDF[y]:
   for match in re.finditer(pat,txt):
    snippet=txt[match.start():match.start()+1800]
    # Stop at the next main question (avoid treating answer rows as questions).
    stop=re.search(r'\n\s*(?:P|S)?\d{1,2}[.\-]+\s*(?:¿|En |Y |Ahora |Con |Durante |Usando |Independientemente|Pensando|Dígame)',snippet[15:])
    if stop:snippet=snippet[:stop.start()+15]
    snippet=re.sub(r'\s+',' ',snippet).strip()[:1500]
    tokens=set(re.findall(r'\w{4,}',norm(label)))
    overlap=len(tokens & set(re.findall(r'\w{4,}',norm(snippet))))
    # Require semantic agreement with source label where meaningful.
    if (overlap>=min(2,len(tokens)) and tokens) or v in ['sex','edad','escol','EDAD','Edad']:candidates.append((overlap,page,snippet,'Ancla de pregunta; revisar batería/subítem'))
 if candidates:
  _,page,snippet,method=max(candidates,key=lambda a:a[0]); return primary[y]+'.pdf',page,snippet,method
 # Fall back to a verbatim phrase search, never fabricate missing wording.
 s=norm(label)
 s=re.sub(r'^\([^)]*\)\s*','',s)
 for length in [55,40,30]:
  if len(s)<length:continue
  needle=s[:length]
  for page,txt in PDF[y]:
   compact=re.sub(r'\s+',' ',txt).strip(); normtxt=norm(compact)
   pos=normtxt.find(needle)
   if pos>=0:
    return primary[y]+'.pdf',page,compact[max(0,pos-80):pos+950],'Frase de etiqueta localizada; fragmento de contexto'
 return '',None,'','No localizado automáticamente; conservar etiqueta Stata, revisar PDF'

def nonsub(label,code):
 n=norm(label)
 if str(code) in ['nan','']:return True
 return bool(re.search(r'^(n/?s(?:\b|/)|n/?c(?:\b|/)|dk\b|no sabe|no contest|no respond|no respuesta|no aplica|no clasificable|no lo conoz|no se suficiente|no he oido|no he escuch|insuf|sin inform|missing)',n))

def substantive_count(r,cid):
 if not r['counts']:return r['n']-r['missing'], 'Excluye solo perdidos del sistema; revisar reglas'
 total=0
 for key,num in r['counts'].items():
  try:value=float(key)
  except ValueError:value=None
  lab=r['codes'].get(str(int(value)),'') if value is not None and math.isfinite(value) and value.is_integer() else ''
  if nonsub(lab,key):continue
  if cid=='isco' and (value is None or value<=0):continue
  if cid in ['ideology','like_pan','like_pri','like_prd','like_pt','like_pvem','morena','amlo'] and not (value is not None and 0<=value<=10):continue
  if cid.startswith('ideology_') and not (value is not None and (1<=value<=11 if r['year']==2018 else 0<=value<=10)):continue
  if cid=='clean' and not (value is not None and 1<=value<=5):continue
  total+=num
 return total,'Excluye perdidos del sistema y códigos especiales etiquetados; no ajusta universo/filtros'

details=[];codes=[];summary=[];members=collections.defaultdict(set)
for c in CONCEPTS:
 present=0; usable=0; evidence_count=0; maps=[]
 if c['id'].startswith('ideology_'):
  c['note']='2018 almacena códigos 1–11 para respuestas 0–10; después y antes utiliza 0–10. Los códigos especiales del PDF 2018 también difieren del archivo: usar etiquetas Stata. Verificar partido en la fila de batería.'
 if c['id']=='vote_main':c['note']+=' 2003 requiere combinar pelea1 y pelea3; el linaje de vote2003b no está etiquetado.'
 if c['id']=='attendance':c['note']+=' La dirección numérica se invierte desde 2003. En 2018 códigos especiales son 7/8, distintos de otras olas.'
 for y in YEARS:
  vs=getvars(y,c['mapping'][y]);maps.append('; '.join(vs) or 'No localizado')
  if not vs:
   details.append([c['id'],c['name'],y,'No localizado','','','','',None,None,None,None,'No localizado','',None,'',c['note'],''])
   continue
  present+=1; usable_y=False
  for v in vs:
   r=LOOK[y,v];members[y,v].add(c['id']); cnt,definition=substantive_count(r,c['id']); usable_y|=cnt>0
   f,page,excerpt,method=locate(y,v,r['label'])
   if f:evidence_count+=1
   derived=''
   if c['derived']:
    candidate=f"{c['derived'][0]}{y}{c['derived'][1]}"
    if (y,candidate) in LOOK:derived=candidate;members[y,candidate].add(c['id'])
   detailnote=c['note']
   if c['id']=='age_group' and y in [2012,2015,2021,2024]:detailnote+=' Fuente mapeada ya agrupada; la pregunta de edad cumplida es S1.'
   if c['id']=='state':detailnote+=f" Se observan {r['unique']} códigos distintos, no necesariamente 32 entidades."
   details.append([c['id'],c['name'],y,'Localizado',v,derived,r['label'],'; '.join(f'{k} = {val}' for k,val in r['codes'].items()),r['n'],r['missing'],cnt,cnt/r['n'],method,f,page,excerpt,detailnote,r['source']])
   for rv,role in [(v,'Original/mapeada')]+([(derived,'Recodificada existente')] if derived and derived!=v else []):
    obj=LOOK[y,rv]
    # Include declared value labels and observed unlabelled values where the domain is reasonably bounded.
    keys=set(obj['codes'])
    for k in obj['counts']:
     if k=='nan':keys.add('Perdido del sistema')
     elif k=='':keys.add('Texto vacío')
     else:
      try:keys.add(str(int(float(k))) if float(k).is_integer() else k)
      except ValueError:keys.add(k)
    if not keys:keys={'Sin dominio enumerado'}
    for k in sorted(keys,key=lambda z:(0,float(z)) if re.fullmatch(r'-?\d+(\.\d+)?',z) else (1,z)):
     lab=obj['codes'].get(k,'Sin etiqueta de valor')
     if k=='Perdido del sistema':count=obj['missing'];typ='Perdido del sistema'
     elif k=='Texto vacío':count=obj['counts'].get('',0);typ='Texto vacío'
     elif k=='Sin dominio enumerado':count=None;typ='Continuo/alta cardinalidad'
     else:
      count=obj['counts'].get(k,obj['counts'].get(k+'.0',0)) if obj['counts'] else None
      typ='Especial según etiqueta' if nonsub(lab,k) else 'Revisar' if lab=='Sin etiqueta de valor' else 'Respuesta/categoría'
     codevalue=int(k) if re.fullmatch(r'-?\d+',k) else float(k) if re.fullmatch(r'-?\d+\.\d+',k) else k
     codes.append([c['id'],c['name'],y,rv,role,codevalue,lab,count,typ,obj['source']])
  usable+=int(usable_y)
 summary.append([c['id'],c['name'],c['domain'],present,usable,c['decision'],c['note'],c['rule'],*maps])

inventory=[]
for r in META:
 inventory.append([r['year'],r['var'],r['label'],r['label_raw'],r['n'],r['missing'],r['missing']/r['n'],r['unique'],r['dtype'],len(r['codes']),'; '.join(sorted(members[r['year'],r['var']])) or 'Sin evaluación semántica detallada en esta entrega',r['source']])

notes=[
 ['Propósito','Inventario de candidatos para decidir qué armonizar. Las decisiones son propuestas metodológicas; el archivo no transforma ni modifica las bases.'],
 ['Alcance','Se inventariaron 3,305 columnas en diez bases (20,317 registros). Se seleccionaron 51 conceptos mediante nombres, etiquetas, recodificaciones existentes y búsqueda en cuestionarios. No se afirma que esta lista agote toda equivalencia semántica posible.'],
 ['Cobertura','Olas con variable cuenta presencia de los campos mapeados. Olas con datos cuenta olas con al menos un valor no excluido por las reglas descritas; no certifica representatividad ni equivalencia. No localizado no significa ausencia demostrada.'],
 ['Lectura','Empezar por Resumen; filtrar olas con variable = 10 y revisar decisión/advertencias. Detalle contiene nombres por año, etiquetas Stata, fragmentos de cuestionario y fuentes. Codigos desglosa categorías originales y recodificadas. Inventario incluye todas las columnas.'],
 ['Texto de preguntas','Etiqueta Stata puede estar truncada y presentar errores de codificación heredados. Fragmento PDF reproduce contexto localizado por ancla/frase, puede incluir instrucciones, batería u otro ítem y no sustituye una validación manual completa de cada pregunta. Se informa el método de localización. Si no se localizó, el texto queda vacío.'],
 ['Versiones','Los fragmentos documentales usan un cuestionario principal por año (versión 1 cuando hay varias). Los campos proceden de la base combinada. Revisar versiones y filtros antes de implementar; en 2003 se muestran ambas boletas y en 2006 una discrepancia de etiquetas.'],
 ['Valores disponibles','N útil provisional excluye perdidos del sistema, texto vacío y códigos especiales identificados por etiqueta. Escalas 0–10 y limpieza 1–5 usan sus límites; ISCO solo códigos positivos. Códigos no etiquetados requieren revisión. No se usa N útil como denominador analítico definitivo.'],
 ['Códigos no observados','Codigos muestra etiquetas declaradas aunque tengan cero casos. Celdas de frecuencia vacías corresponden a dominios de alta cardinalidad no enumerados, no a cero casos. Un código sin etiqueta no se clasifica automáticamente como no respuesta.'],
 ['Aprobación','Aprobación presidencial conserva la comprobación previa de la relación original→a/b en 20,317 registros. Para otras recodificaciones, esta entrega documenta etiquetas y valores; no certifica que cada regla sea correcta.'],
 ['Edad y sexo','La lectura directa de Stata sí recuperó las etiquetas de female<año> y age<año>b. Esto corrige la limitación indicada previamente en la documentación del paquete. El último grupo aparece como 61–96 en recodificadas; 1997/2000 originales dicen 61+.'],
 ['ISCO 2021','Los 1,800 registros de isco08_1_ES son -9. Tener columna en las diez olas no constituye una serie ocupacional utilizable de diez olas.'],
 ['Identificación partidista','Los códigos de pid<año>b cambian: por ejemplo 3 = PRD en 1997 y 3 = MORENA en 2021. En 2024 existe MC explícito. Unir etiquetas/categorías, no códigos numéricos.'],
 ['Voto 2006','peledip tiene etiqueta de SENADORES y pelesen etiqueta de diputados federales. Se incluyen como campos a resolver; el cuestionario por sí solo no demuestra cuál columna fue almacenada correctamente.'],
 ['Precinct','precinct clasifica rural/mixta/urbana y no identifica sección electoral. Cambian códigos entre olas; no usar directamente como UPM.'],
 ['Ingreso','NSE e income<año>c requieren auditoría de puntos de corte. 2018 usa código 5 para el grupo 5+ SM; otros años código 4. No se verificaron deflactores ni equivalencia de salarios mínimos.'],
 ['Ponderación','Las frecuencias del libro no están ponderadas. Conservar año y pesos por ola; los pesos por sí solos no reconstruyen estratos ni conglomerados.'],
 ['Fuentes','Archivos locales ENEM_<año>_isco08.dta y cuestionarios PDF indicados por nombre/página. No hay URL pública verificada para estos archivos originales; no se inventan enlaces.'],
 ['Criterios de decisión','Priorizar: buen candidato conceptual con escala común, sujeto a implementación verificada. Con ajustes: candidato que requiere reglas explícitas. Solo subserie: cobertura incompleta localizada. Revisar antes: conflicto o carencia impide adoptar la serie. No unir directamente: homonimia o mezcla conceptual. Auxiliar: metadato de diseño/identificación.']
]
bundle=dict(summary=summary,details=details,codes=codes,inventory=inventory,notes=notes,years=YEARS)
(BASE/'workbook_data.json').write_text(json.dumps(bundle,ensure_ascii=False,allow_nan=False),encoding='utf8')
print('Summary',len(summary),'details',len(details),'codes',len(codes),'inventory',len(inventory))
print('10-wave candidates',sum(r[3]==10 for r in summary),'10-wave with some data',sum(r[4]==10 for r in summary))
print('Decisions',dict(collections.Counter(r[5] for r in summary)))
print('PDF located',sum(bool(r[13]) for r in details),'of',sum(r[3]=='Localizado' for r in details))
for row in summary: print(row[0],row[3],row[4],row[5])
