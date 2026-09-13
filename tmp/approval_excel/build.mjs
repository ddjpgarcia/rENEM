import fs from 'node:fs/promises';
import {Workbook,SpreadsheetFile} from '@oai/artifact-tool';
const output='C:/enemR-project/rENEM/outputs/01a08271-1276-79c3-980d-1d55ded75b74';
const scratch='C:/enemR-project/rENEM/tmp/approval_excel';
const evidence=JSON.parse(await fs.readFile(scratch+'/evidence.json','utf8'));
const wb=Workbook.create();
const specs=[
 [1997,'p23','Zedillo','23','1997.pdf, p. 7'],
 [2000,'pacu','Zedillo','67 (ACU)','2000.pdf, p. 22'],
 [2003,'p28','Fox','28 (ACU)','2003 conalianza.pdf / 2003 sinalianza.pdf, p. 7'],
 [2006,'p46','Fox','46 (ACU)','2006 Version 1.pdf, p. 15 / 2006 Version 2.pdf, p. 13'],
 [2009,'pacu','Felipe Calderón','ACU','2009 Version 1.pdf / 2009 Versión 2.pdf, p. 6'],
 [2012,'p42','Felipe Calderón','42 (ACU)','2012.pdf, p. 7'],
 [2015,'p48','Enrique Peña Nieto','48 (ACU)','2015 Version 1 Publicidad.pdf, p. 8 / 2015 Version 2 Clientelismo.pdf, p. 6'],
 [2018,'p15','Enrique Peña Nieto','P15','2018 CSES.pdf, p. 5'],
 [2021,'P2','López Obrador','2','2021 Version 1 Erosion Democratica.pdf / 2021 Version 2 Ideologia.pdf, p. 1'],
 [2024,'P2','López Obrador','2','2024 Version 1, 2 y 3.pdf, p. 1']
];
function sheet(name,headers,rows,widths,height){
 const s=wb.worksheets.add(name); s.showGridLines=false;
 const n=rows.length+1, m=headers.length;
 s.getRangeByIndexes(0,0,n,m).values=[headers,...rows];
 s.getRangeByIndexes(0,0,n,m).format.font={name:'Arial',size:11,color:'#243247'};
 s.getRangeByIndexes(0,0,n,m).format.wrapText=true;
 s.getRangeByIndexes(0,0,n,m).format.verticalAlignment='top';
 s.getRangeByIndexes(0,0,1,m).format={fill:'#273E56',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},wrapText:true,rowHeight:34};
 s.getRangeByIndexes(1,0,rows.length,m).format.rowHeight=height;
 widths.forEach((w,i)=>s.getRangeByIndexes(0,i,n,1).format.columnWidth=w);
 for(let r=2;r<n;r+=2)s.getRangeByIndexes(r,0,1,m).format.fill='#F1F5F9';
 s.tables.add(s.getRangeByIndexes(0,0,n,m),true,name+'Table');
 s.freezePanes.freezeRows(1);
 return s;
}
const questionRows=specs.map(([y,v,p,q,src])=>[
 y,v,'Serie comparable',
 y===1997?'¿Está usted de acuerdo o en desacuerdo con la manera como está gobernando el Presidente Zedillo?':`En general, ¿está usted de acuerdo o en desacuerdo con la manera como está gobernando el presidente ${p}?`,
 '1 = Acuerdo\n2 = Acuerdo en parte\n3 = Desacuerdo en parte\n4 = Desacuerdo',
 y<2003?'5 = No sabe\n6 = No contesta':y<2021?'8 = No sabe\n9 = No contesta':'98 = No sabe\n99 = No contesta',
 q,src,
 y===2018?'Ítem completo marcado ESPONTÁNEA. Evalúa a Peña Nieto. Variable original en minúsculas: p15.':y===2015?'Opciones 2 y 3 espontáneas. Etiqueta adicional 97 = No aplica por versión, sin casos observados.':'Opciones 2 y 3 espontáneas.',
 `ENEM_${y}_isco08.dta`
]);
questionRows.push([2003,'p31a','Ítem adicional','En general, ¿aprueba totalmente, aprueba, desaprueba, o desaprueba totalmente el desempeño hasta estos momentos de Vicente Fox como presidente de México?','1 = Aprueba totalmente\n2 = Aprueba\n3 = Desaprueba\n4 = Desaprueba totalmente','8 = No sabe\n9 = No contesta','31a','2003 conalianza.pdf / 2003 sinalianza.pdf, p. 7','Escala de intensidad distinta. Para la serie comparable se selecciona p28.','ENEM_2003_isco08.dta']);
const p=sheet('Preguntas',['Año','Variable original','Selección','Texto de la pregunta','Respuestas sustantivas','No respuesta','Número en cuestionario','Fuente de la pregunta','Notas de comparabilidad','Fuente de códigos'],questionRows,[9,17,22,65,30,22,20,44,49,32],104);
p.getRange('A2:A12').setNumberFormat('0');
let codeRows=[];
for(const r of evidence){
 const y=r.year,v=specs.find(s=>s[0]===y)[1],d=r.variables[v];
 for(const [code,label] of Object.entries(d.value_labels)){
  const c=Number(code),count=d.counts[c+'.0']??d.counts[String(c)]??0;
  codeRows.push([y,v,c,label,count,`approval${y}a`,c<=4?5-c:c===97?null:5,`approval${y}b`,c<=4?5-c:null,c===97?'Código definido, no observado. No se infiere su recodificación.':c<=4?'Escala invertida: 1 = desaprobación; 4 = aprobación.':'a: NS/NC agrupados como 5 (DK). b: valor perdido.',`ENEM_${y}_isco08.dta`]);
 }
}
const c=sheet('Codigos',['Año','Variable original','Código original','Etiqueta Stata original','Casos sin ponderar','Variable recodificada a','Código a','Variable recodificada b','Código b','Interpretación','Fuente'],codeRows,[9,17,15,30,18,24,14,24,14,56,32],48);
for(const col of ['A','C','E','G','I'])c.getRange(`${col}2:${col}${codeRows.length+1}`).setNumberFormat('0');
const noteRows=[
 ['Alcance','ENEM 1997–2024: diez bases. Se documenta la aprobación del presidente en funciones. La hoja Preguntas contiene diez ítems comparables y un ítem adicional de 2003.'],
 ['Fuentes','Texto completo: cuestionarios originales en PDF. Nombres, códigos, etiquetas y frecuencias: archivos ENEM_<año>_isco08.dta. Los nombres de archivos y páginas figuran en las tablas. No se usaron etiquetas truncadas para reconstruir el texto.'],
 ['Dirección de la escala','Original: 1 = acuerdo y 4 = desacuerdo. Recodificadas a/b: 1 = desaprobación, 2 = desaprobación parcial, 3 = aprobación parcial, 4 = aprobación.'],
 ['Valores perdidos','NS = No sabe; NC = No contesta. En las recodificadas a, ambos se agrupan en 5, etiquetado DK. En las recodificadas b, ambos son valores perdidos (celdas vacías en Código b).'],
 ['Comprobación de recodificaciones','La correspondencia entre el ítem original y las recodificadas a/b se comprobó en los 20,317 registros de las diez bases. Casos sin ponderar son frecuencias, no estimaciones de aprobación.'],
 ['2015','p48 define 97 = No aplica por versión, pero no hay registros con ese valor. No se deduce una regla de recodificación para 97.'],
 ['2018','p15 evalúa a Enrique Peña Nieto. El cuestionario CSES marca el ítem completo como ESPONTÁNEA. Este resultado se refiere a la base disponible, no a cada medición del panel de 2018.'],
 ['2003: p31a','Ítem adicional con categorías Aprueba totalmente / Aprueba / Desaprueba / Desaprueba totalmente. p28 conserva la formulación compartida por las otras olas. Los códigos de p31a están en Preguntas.'],
 ['Disponibilidad en el paquete','Las recodificadas approval<año>a y approval<año>b existen en las bases originales examinadas. Esta documentación no modifica enem_panel ni incorpora nuevas variables al paquete.']
];
sheet('Notas',['Tema','Detalle'],noteRows,[32,115],64);
await fs.mkdir(output,{recursive:true});
console.log((await wb.inspect({kind:'table',range:'Preguntas!A1:C12',tableMaxRows:12,tableMaxCols:3,maxChars:2000})).ndjson);
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#NUM!',options:{useRegex:true,maxResults:20},maxChars:1000})).ndjson);
for(const [name,range] of [['Preguntas','A1:F5'],['Codigos','A1:K8'],['Notas','A1:B10']]){
 const img=await wb.render({sheetName:name,range,scale:1,format:'png'});
 await fs.writeFile(scratch+'/'+name+'.png',new Uint8Array(await img.arrayBuffer()));
}
const file=await SpreadsheetFile.exportXlsx(wb); await file.save(output+'/ENEM_aprobacion_presidencial_1997_2024.xlsx');
console.log('Saved '+output+'/ENEM_aprobacion_presidencial_1997_2024.xlsx');
