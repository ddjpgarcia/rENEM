import json,re,unicodedata
from pathlib import Path
BASE=Path(__file__).parent
META=json.loads((BASE/'metadata.json').read_text(encoding='utf8'))
YEARS=[1997,2000,2003,2006,2009,2012,2015,2018,2021,2024]
LOOK={(r['year'],r['var']):r for r in META}
CONCEPTS=[]
def add(id,name,domain,mapping,decision,note,rule,derived=None):
    if isinstance(mapping,str):mapping=mapping.split('|')
    if len(mapping)!=10:raise ValueError(id)
    CONCEPTS.append(dict(id=id,name=name,domain=domain,mapping=dict(zip(YEARS,mapping)),decision=decision,note=note,rule=rule,derived=derived))
def from_recode(family,suffix):
    result=[]
    for y in YEARS:
        v=f'{family}{y}{suffix}'; seen=set()
        while (y,v) in LOOK and v not in seen:
            seen.add(v); m=re.search(r'RECODE of (\w+)',LOOK[y,v]['label'])
            if not m:break
            target=m[1]
            if (y,target) not in LOOK:
                target=next((r['var'] for r in META if r['year']==y and r['var'].lower()==target.lower()),target)
            if (y,target) not in LOOK:break
            v=target
        result.append(v)
    return result
add('approval','Aprobación presidencial','Opinión',from_recode('approval','b'),'Priorizar','Mismo referente: presidente en funciones. Difieren los códigos NS/NC.','Original 1–4; recodificar 1→4, 2→3, 3→2, 4→1; NS/NC a perdido.',('approval','b'))
add('satisfaction','Satisfacción con la democracia','Opinión',from_recode('satisfaction','b'),'Con ajustes','1997/2000 dicen regularmente satisfecho; después satisfecho. Mantener nota de formulación.','Cuatro niveles ordinales; unificar dirección y no respuesta.',('satisfaction','b'))
add('ideology','Autoubicación izquierda–derecha','Opinión',from_recode('ideology','b'),'Priorizar','Escala 0–10; no confundir con liberal–conservador ni tratar DK como centro.','Conservar 0 = izquierda, 10 = derecha; otros códigos según etiquetas.',('ideology','b'))
for party in ['pan','pri','prd']:
 add('like_'+party,'Evaluación del '+party.upper(),'Partidos',from_recode(party,'b'),'Priorizar','Mismo partido y escala de agrado. La posición del partido en la batería cambia.','Conservar 0–10; separar NS, NC y no conoce suficiente.',(party,'b'))
add('pid','Identificación partidista','Partidos',from_recode('pid','b'),'Con ajustes','Se pasa de simpatía con filtro a identificación directa; cambia el sistema de partidos. En pid2021b, 3 = MORENA; antes 3 = PRD.','Reconstruir desde originales y filtros; usar etiquetas de partido, no apilar códigos b.',('pid','b'))
add('sex','Sexo registrado','Demografía',from_recode('female',''),'Priorizar','Categorías documentadas hombre/mujer; variable de sexo registrada, no identidad de género.','0 = hombre, 1 = mujer; preservar no respuesta.',('female',''))
add('age_group','Edad agrupada','Demografía',from_recode('age','b'),'Con ajustes','Las recodificadas sí tienen etiquetas de valor: 18–25, 26–40, 41–60, 61–96. Verificar edades fuera del límite superior.','Auditar límites contra edad original; definir último grupo 61+ solo tras comprobar los datos.',('age','b'))
add('education','Escolaridad','Demografía',from_recode('education',''),'Con ajustes','Cuatro grupos existentes ocultan años incompletos y ausencia de estudios.','Construir niveles desde etiquetas originales; documentar inclusión de sin estudios.',('education',''))
add('religion','Religión','Demografía',from_recode('religion','b'),'Con ajustes','Categorías originales cambian; recodificación b propone católica/otra/ninguna. No confundir no religión con NS.','Usar católica, otra religión, ninguna; conservar desagregación original.',('religion','b'))
add('income','Ingreso familiar','Demografía',from_recode('income','c'),'Revisar antes','Rangos en pesos/salarios mínimos cambian. income2018c usa 5 para 5+ SM; otras olas usan 4. Una escala etiquetada igual no prueba igualdad de poder adquisitivo.','Revisar umbrales y unidades por año; no comparar códigos o pesos nominales directamente.',('income','c'))
add('urban','Tipo de sección rural/mixta/urbana','Geografía',from_recode('precinct',''),'Con ajustes','1997/2000: recodificadas 0 rural, 1 urbana. Desde 2003: 1 rural, 2 mixta, 3 urbana. No es ID de sección.','Rural/mixta/urbana por etiqueta; no asignar mixta en olas donde no se distingue.',('precinct',''))
add('econ_retro','Economía nacional: últimos 12 meses','Economía','p10|p13|p35|p30|p63|p12|p15|P17|P15|P15B','Con ajustes','Mismo periodo y ámbito nacional; algunas olas usan seguimientos de intensidad o igual de bien/mal.','Mejoró / igual / empeoró; intensidad en variable separada.')
add('econ_now','Economía nacional: situación actual','Economía','p9|p12|p34|p29|p62|p76||SITECO|P14|P15A','Solo subserie','No localizado equivalente en 2015. No sustituir por cambio de economía ni situación del estado.','Cinco categorías buena–mala según etiquetas; conservar NS/NC.')
add('econ_personal','Economía personal: últimos 12 meses','Economía','p26|p32|p38|p33||p74|p73|P27O1||P15C','Solo subserie','No localizado equivalente en 2009/2021. P42 de 2021 pregunta efecto de la pandemia, no el mismo constructo temporal.','Mejoró / igual / empeoró; separar seguimientos de intensidad.')
add('clean','Percepción de limpieza electoral','Elecciones','p2|p5|p31|p76|p66|p46|p49|P33|P19|P11','Con ajustes','Escala 1–5; refiere a la elección de cada ola. Algunos reactivos requieren verificar variantes.','1 = no limpia, 5 = limpia; fuera de escala según etiquetas.')
add('matters_party','Importa qué partido gobierna','Eficacia','p13|p17|p9|p4|p4|p14|p17|P18||P12','Solo subserie','No localizado equivalente en 2021. No sustituirlo por influencia del voto.','Unificar escala 1–5 por sus extremos.')
add('matters_vote','Influencia del voto','Eficacia','p14|p18|p10|p5|p5|p15|p18|P19|P21|','Solo subserie','No localizado equivalente en 2024. Es distinto de importa qué partido gobierna.','1–5: mayor valor = mayor influencia; revisar cuestionarios.')
add('issue','Principal problema del país','Opinión','p22|p21|p5|p2|p59|p2|p2|P40||P3','Solo subserie','Cambian referente gobierno/país, horizonte y modo abierto/tarjeta. No localizado en 2021.','Taxonomía temática revisada manualmente; no unir números de categoría.')
add('interest','Interés en la política','Participación','||||p30|||P6|P5|P7','Solo subserie','Interés no equivale a atención a campaña o frecuencia de noticias. 2009 incluye política y gobierno, con cinco niveles.','Conservar escala original; acordar categorías comunes antes de comparar.')
add('turnout','Participación electoral declarada','Elecciones','p17|p1|p3|pi|pi|p3|p3|P9|P16|P8','Con ajustes','Alterna elección presidencial y legislativa. Revisar filtros y categorías no tenía edad.','Sí/no con tipo y año de elección; no confundir no votó con no respuesta.')
add('vote_main','Voto de la recodificación existente','Elecciones','peleb|pelea|pelea1|pelepre|peledip|pelepre|peledip|PELEPRE|PELEDIP|PELEPDTE','No unir directamente','vote<año> mezcla presidente y diputados; coaliciones y códigos de partido varían.','Separar cargo, partido y coalición; no usar una única variable de voto indiferenciada.',('vote','b'))
add('vote_dip','Voto para diputados federales','Elecciones','peleb|peleb|pelea1;pelea3|peledip;pelesen|peledip|peledip|peledip|PELEDIP|PELEDIP|PELEDIP','Revisar antes','2003 tiene boletas por versión. En 2006 las etiquetas de peledip/pelesen parecen intercambiadas; no elegir por nombre.','Resolver la discrepancia 2006 y unir boletas por versión antes de armonizar partidos.')
add('chambers','Conocimiento: cámaras del Congreso','Conocimiento','p52_1;p52_2;p52_3;p52_4|pcam|p25|p27|p24|p69|p67|CAMARAS|P47|P26_1','Con ajustes','1997 separa menciones; olas recientes pueden almacenar correcto/incorrecto. 2018 contiene duplicados.','Correcto = diputados y senadores; separar incorrecto y NS/NC.')
add('term','Conocimiento: duración de diputado','Conocimiento','p53|pdip|p26|p27a|p24a|p70|p68|DIPUTADOS|P48|P26_2','Con ajustes','Cambian representación numérica y evaluación correcto/incorrecto.','Tres años = correcto; no confundir código 1 con un año.')
add('governor','Conocimiento: nombre del gobernador','Conocimiento','p57|pgob|p27|p27b|p24b|p71|p69|GOBERNADOR|P49|P26_3','Con ajustes','El nombre correcto depende de estado/fecha; DF/CDMX usa jefe de gobierno.','Usar indicador de conocimiento cuando exista; validar textos por estado y fecha.')
add('marital','Estado civil','Demografía','se20|se16|s16|ps16|ps16|s4|ps4|S4|S4|S4','Con ajustes','Separación/divorcio/unión libre pueden agruparse distinto.','Mapa por etiquetas a categorías comunes, conservando original.')
add('activity','Actividad principal','Trabajo','se4|se4|s4|ps4|ps4|s8|ps5|S7|S7|S6','Con ajustes','Actividad de la semana pasada; cambian estudio/trabajo/búsqueda/quehaceres y filtros.','Ocupado / desocupado / fuera de fuerza laboral solo con definición y seguimientos consistentes.')
add('attendance','Asistencia a iglesia o templo','Religión','se26|se24|s24|ps24|ps24|s28|ps20|S13|S13|S12','Con ajustes','Desde 2012 se explicita excluir ocasiones especiales; frecuencia y categorías varían.','Categorías comunes de frecuencia; no asignar días exactos a intervalos abiertos.')
add('ethnicity','Autoidentificación étnico-racial','Demografía','se29|se22|s22|ps22|ps22|s32|ps26|S16_1|S16|S15','Con ajustes','Cambia raza/grupo y en 2024 se añade afrodescendiente explícitamente.','Conservar indígena/mestizo/blanco/otro y categorías nuevas; no suponer equivalencia del residual.')
add('indigenous','Habla lengua indígena','Demografía','|se26|s26|ps26|ps26|s33|ps27|S17|S17|S16','Solo subserie','No localizado ítem directo en 1997; etnicidad no sustituye lengua.','Sí/no; preservar NS/NC; no inferir por autoidentificación.')
add('home_language','Idioma usual del hogar','Demografía','||s27|ps27|ps27|s31|ps25|S15|S15|S14','Solo subserie','No localizado en 1997/2000. No equivale a hablar una lengua indígena.','Español / lengua indígena / otro con revisión de respuestas abiertas.')
add('household','Tamaño del hogar','Demografía','se23|se20|s20|ps20|ps20|s25|ps17|||','Solo subserie','No localizado en 2018/2021/2024. Miembros no equivale a dependientes del ingreso.','Número de personas incluyendo entrevistado; limpiar códigos especiales.')
add('isco','Ocupación ISCO-08','Trabajo',['isco08_1_ES']*10,'Revisar antes','2021: todos los registros son -9. En 1997 solo hay dos códigos ocupacionales positivos. Mismo catálogo no implica misma cobertura.','Separar -9 no aplica, -8 no clasificable, -7 no respuesta; reparar codificación antes de serie completa.')
add('weight_final','Ponderador final','Diseño',['PONDFIN']*10,'Conservar como auxiliar','Presente en todas; no es pregunta. No basta para reconstruir UPM/estratos.','Mantener por ola; definir normalización antes de análisis combinado.')
add('weight_design','Ponderador de diseño','Diseño',['PONDERADOR']*10,'Conservar como auxiliar','Presente en todas; revisar ficha de cada ola antes de interpretar.','Mantener por ola; no sustituir automáticamente el ponderador final.')
add('nse','NSE preexistente','Derivadas',['NSE']*10,'No unir directamente','Mismo nombre, umbrales distintos: 1997 3–5/5–7/7+ SM; 2000 3–6/6–8/8+ SM.','Reconstruir desde ingreso original y reglas documentadas.')
add('copartisan','Copartidismo preexistente','Derivadas',['copartisan']*10,'Revisar antes','Mismas etiquetas no identifican por sí solas el partido de referencia de cada ola.','Reconstruir usando identificación partidista y partido del presidente en funciones.')
add('id','Identificador id','Identificadores',['id']*10,'Conservar como auxiliar','Nombre común no prueba identidad longitudinal ni unicidad al apilar años.','Comprobar unicidad dentro de ola; construir llave año+ID si procede.')
add('state','Entidad federativa','Geografía','ESTADO|ESTADO|edo|ESTADO|ESTADO|estado|estado|ESTADO|EDO|EDO','Revisar antes','Comprobar códigos, etiquetas y cobertura territorial por ola.','Cruce documentado de entidades; no tratar números como escala.')
add('municipality','Municipio','Geografía','MUNICIPIO||muni|MPIO|MPIO|edompio|mpio|MPIO|mpio|mpio','Solo subserie','2000 sin variable mapeada; 2012 usa estado–municipio. Códigos locales cambian.','Cruzar entidad y municipio con catálogo de época; conservar dato original.')
add('morena','Evaluación de MORENA','Partidos','||||||p19h|P20_8|P22_4|P16_4','Solo subserie','El partido no integra toda la serie; no rellenar años anteriores con cero.','0–10; ausente estructuralmente en años anteriores.',('morena','b'))
add('amlo','Evaluación personal de López Obrador','Líderes','p8_5|||p10c|p10d|p17_3||P21_3|P23_1|P17_4','Solo subserie','Cambia rol de dirigente/candidato/presidente. No equivale a aprobación presidencial.','0–10 con indicador del rol y del contexto electoral.',('amlo','b'))
for party,idx in [('pan',0),('pri',1),('prd',2)]:
 arr=[f'p16_{idx+2}',f'p20_{idx+2}',f'p20_{idx+1}',f'p11{chr(97+idx)}',f'p11{chr(97+idx)}',f'p18_{idx+1}',f'p20{chr(97+idx)}',f'P22_{idx+1}',f'P24_{idx+1}',f'P18_{idx+1}']
 add('ideology_'+party,'Ubicación izquierda–derecha del '+party.upper(),'Partidos',arr,'Con ajustes','La tabla del cuestionario determina el partido; etiquetas genéricas pueden truncarlo.','Conservar 0 izquierda–10 derecha; verificar orden de filas y NS/NC.')

add('like_pt','Evaluación del PT','Partidos','p7_4|p10_4|p19_5|p9e|p9e|p16_5|p19e|P20_5|P22_6|P16_6','Con ajustes','Verificar orden de partidos en batería; mismo partido no implica mismo código de columna.','Conservar 0–10 según cuestionario; limpiar valores especiales por año.')
add('like_pvem','Evaluación del PVEM','Partidos','p7_5|p10_5|p19_4|p9d|p9d|p16_4|p19d|P20_4|P22_5|P16_5','Con ajustes','Verificar orden de partidos en batería; mismo partido no implica mismo código de columna.','Conservar 0–10 según cuestionario; limpiar valores especiales por año.')
add('ideology_pt','Ubicación izquierda–derecha del PT','Partidos','p16_5|p20_5|p20_5|p11e|p11e|p18_5|p20e|P22_5|P24_6|P18_6','Con ajustes','2018 almacena 1–11 para respuestas 0–10: usar etiquetas y restar uno a códigos sustantivos.','Conservar 0–10; verificar partido por fila de batería.')
add('ideology_pvem','Ubicación izquierda–derecha del PVEM','Partidos','p16_6|p20_6|p20_4|p11d|p11d|p18_4|p20d|P22_4|P24_5|P18_5','Con ajustes','2018 almacena 1–11 para respuestas 0–10: usar etiquetas y restar uno a códigos sustantivos.','Conservar 0–10; verificar partido por fila de batería.')

def getvars(y,s):
 return [v for v in s.split(';') if v]
if __name__=='__main__':
 bad=[]
 for c in CONCEPTS:
  for y,s in c['mapping'].items():
   for v in getvars(y,s):
    if (y,v) not in LOOK:bad.append((c['id'],y,v))
 print('Concepts',len(CONCEPTS),'Missing mappings',bad)
 (BASE/'concepts.json').write_text(json.dumps(CONCEPTS,ensure_ascii=False,indent=2),encoding='utf8')
